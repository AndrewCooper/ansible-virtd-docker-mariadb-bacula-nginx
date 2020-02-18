#! /bin/bash

INVENTORY="staging"
PLAYBOOK="site.yml"
VERBOSITY="v"

while getopts "i:p:v" OPTION; do
  case $OPTION in
  i)
    INVENTORY="$OPTARG"
    ;;
  p)
    PLAYBOOK="$OPTARG"
    ;;
  v)
    VERBOSITY="${VERBOSITY}v"
    ;;
  *)
    echo "Incorrect options provided"
    exit 1
    ;;
  esac
done
shift $((OPTIND-1))

ANSIBLE_ENABLE_TASK_DEBUGGER=True \
ANSIBLE_FORCE_COLOR=true \
ANSIBLE_HOST_KEY_CHECKING=false \
ANSIBLE_SSH_ARGS='-o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes -o ControlMaster=auto -o ControlPersist=60s' \
exec ansible-playbook \
        --connection=ssh \
        --timeout=30 \
        --inventory-file="${INVENTORY}" \
        -${VERBOSITY} \
        "${PLAYBOOK}" "$@"
