#!/bin/bash

#== begin help
# Usage: bash gen-ed25519-ppk.sh [OPTIONS]
# Create a PuTTY PPK v3 format SSH auth key file with ed25519,
# from scratch or from an existing OpenSSH private key file.
# * notice: argon2 command is required to create an encrypted key.
#
#   -h          show this help and exit
#   -e          create an encrypted ( passphrase protected ) key
#   -p pass     passphrase to set ( only valid with -e option )
#   -f keyfile  source OpenSSH ed25519 private key file
#               * this file should be not encrypted
#   -o outfile  file to store the created key
#               * print to stdout without this option set
#   -c comment  comment string to store in the key
#== end help


# global parameters to set from ARGV
do_enc=0
enc_pass=
ssh_key_file=
out_file=
key_comment=

# constants
KEY_ALG='ssh-ed25519'
KEY_ENC_ENC='aes256-cbc'
KEY_ENC_NOENC='none'
PRIV_DATA_LEN=32
PUB_DATA_LEN=32
ENC_PADDING_LEN=12
ENC_KEY_LEN=32
ENC_IV_LEN=16
ENC_HKEY_LEN=32
OSSL_ED25519_DER_PREFIX_HEX=302e020100300506032b657004220420
OSSH_KEY_DATA_OFFSET=161

# argon2 parameters
ARGON2_MEMORY=13
ARGON2_PASSES=8
ARGON2_PARALLELISM=1
ARGON2_LENGTH=$(( ENC_KEY_LEN + ENC_IV_LEN + ENC_HKEY_LEN ))
ARGON2_SALT_LENGTH=16

# global variables
priv_hex=
pub_hex=

# functions
# print an error and exit immediately
function abort() {
  echo "** ${1:-unknown error}, aborted **" >&2
  exit 1
}
# base64 encode with width=64
function base64w64 { base64 -w 64; }
# convert hex string to raw string
function h2s() { xxd -r -p; }
# add length info as a prefix to hex string
function addlen() {
  if [[ -n "$1" ]]; then
    printf -v "$1" %08x%s $(( ${#2}/2 )) "$2"
  else
    printf %08x%s $(( ${#2}/2 )) "$2"
  fi
}
# convert raw string to hex string
function s2h() {
  local cmd='xxd -p -c 256'
  if (( $1 )); then
    addlen "" "$($cmd)"
  else
    $cmd
  fi
}
# show usage after printing a message and exit
function usage() {
  [[ -n "$1" ]] && echo "** $1 **" >&2
  sed -ne '1,/^#== begin help/b; /^#== end help/q; s/^# //p' "$0"
  trap - EXIT
  exit 1
}
# parse argument
function parsearg() {
  local opt
  while getopts :hep:f:o:c: opt; do
    case $opt in
    h) usage;;
    e) do_enc=1
       which argon2 >/dev/null || usage "argon2 command required but not found";;
    p) enc_pass="$OPTARG";;
    f) ssh_key_file="$OPTARG";;
    o) out_file="$OPTARG";;
    c) key_comment="$OPTARG";;
    *) usage "invalid option -$OPTARG is set";;
    esac
  done

  (( $# < $OPTIND )) \
    || usage "an invlalid extra argument \"${!OPTIND}\" found"
  [[ -z $enc_pass || $do_enc = 1 ]] \
    || usage "passphrase set with -p, but no encryption enabled"
}
# load private key or create a new key randomly and set priv_hex/pub_hex
function load_or_new_pkey() {
  local priv_raw_hex
  if [[ -n $ssh_key_file ]]; then
    priv_raw_hex=$(
      grep -v ^- "$ssh_key_file" \
      | base64 -d \
      | dd status=none bs=1 count=$PRIV_DATA_LEN skip=$OSSH_KEY_DATA_OFFSET \
      | s2h
    )
  else
    priv_raw_hex=$(openssl rand -hex $PRIV_DATA_LEN)
  fi
  addlen priv_hex "$priv_raw_hex"
  pub_hex=$(
    h2s <<< "$OSSL_ED25519_DER_PREFIX_HEX$priv_raw_hex" \
    | openssl pkey -inform der -pubout -outform der \
    | tail -c $PUB_DATA_LEN \
    | s2h 1
  )
}
# set FD for key output
function set_output_fd() {
  if [[ -n $out_file ]]; then
    exec {out_fd}> "$out_file"
  else
    out_fd=1
  fi
}
# make an encrypted PPK
function make_ppk_enc() {
  read_passphrase
  # choose salt and set several keys from the passphrase
  local salt_hex
  until (( ${#salt_hex} == ARGON2_SALT_LENGTH*2 )); do
    # avoid zero bytes in salt data
    salt_hex=$(
      openssl rand $((ARGON2_SALT_LENGTH*2)) \
      | tr -d \\0 \
      | head -c $ARGON2_SALT_LENGTH \
      | s2h
    )
  done
  # use argon2 as KDF
  local kdf_val_hex=$(
    echo -n "$enc_pass" \
    | argon2 "$(h2s <<< $salt_hex)" -id -r \
      -m $ARGON2_MEMORY -t $ARGON2_PASSES \
      -p $ARGON2_PARALLELISM -l $ARGON2_LENGTH
  )
  local enc_key_hex=${kdf_val_hex:0:ENC_KEY_LEN*2}
  local enc_iv_hex=${kdf_val_hex:ENC_KEY_LEN*2:ENC_IV_LEN*2}
  local hmac_key_hex=${kdf_val_hex:ENC_KEY_LEN*2+ENC_IV_LEN*2:ENC_HKEY_LEN*2}
  local kdf_lines=(
    "Key-Derivation: Argon2id"
    "Argon2-Memory: $((2**ARGON2_MEMORY))"
    "Argon2-Passes: $ARGON2_PASSES"
    "Argon2-Parallelism: $ARGON2_PARALLELISM"
    "Argon2-Salt: $salt_hex"
  )
  # expand private key data with random padding
  priv_hex+=$(openssl rand -hex $ENC_PADDING_LEN)
  # set encrypted private key
  local priv_enc_hex=$(
    h2s <<< "$priv_hex" \
    | openssl enc -aes-256-cbc -K $enc_key_hex -iv $enc_iv_hex \
    | head -c $(( ${#priv_hex}/2 )) \
    | s2h
  )
  make_ppk_common \
    $KEY_ENC_ENC \
    "$priv_enc_hex" \
    "$hmac_key_hex" \
    "${kdf_lines[@]}" >&${out_fd}
}
# make a non-encrypted PPK
function make_ppk_noenc() {
  # use zero as HMAC key
  local hmac_key_hex
  printf -v hmac_key_hex %064x 0
  # no encryption applied and no kdf lines passed
  make_ppk_common \
    $KEY_ENC_NOENC \
    "$priv_hex" \
    "$hmac_key_hex" >&${out_fd}
}
# read passphrase from stdin if not set with argv
function read_passphrase() {
  [[ -z $enc_pass ]] || return 0
  read -sp 'enter passphrase to set: ' enc_pass
  echo >&2
  [[ -n $enc_pass ]] || abort 'empty passphrase is not allowed'
}
# PPK creation core
function make_ppk_common() {
  local key_enc="$1" priv_enc_hex="$2" hmac_key_hex="$3"
  shift 3  # rest arguments are lines for KDF info
  echo "PuTTY-User-Key-File-3: $KEY_ALG"
  echo "Encryption: $key_enc"
  echo "Comment: $key_comment"
  echo "Public-Lines: 2"
  local key_alg_hex=$(echo -n "$KEY_ALG" | s2h 1)
  h2s <<< "$key_alg_hex$pub_hex" | base64w64 
  local kdf_line
  for kdf_line in "$@"; do
    echo "$kdf_line"
  done
  echo "Private-Lines: 1"
  h2s <<< "$priv_enc_hex" | base64w64
  local comment_hex=$(echo -n "$key_comment" | s2h 1)
  local key_enc_hex=$(echo -n "$key_enc" | s2h 1)
  local pub_full_hex priv_full_hex
  addlen pub_full_hex "$key_alg_hex$pub_hex"
  addlen priv_full_hex "$priv_hex"
  hmac_hex_raw=$(
    h2s <<< "$key_alg_hex$key_enc_hex$comment_hex$pub_full_hex$priv_full_hex" \
    | openssl dgst -sha256 -hex -r -mac HMAC -macopt hexkey:$hmac_key_hex
  )
  echo "Private-MAC: ${hmac_hex_raw% *}"
}

# main procudure
set -o pipefail
set -o errexit
trap abort EXIT
parsearg "$@"
load_or_new_pkey
set_output_fd
if (( do_enc )); then
  make_ppk_enc
else
  make_ppk_noenc
fi
trap - EXIT
