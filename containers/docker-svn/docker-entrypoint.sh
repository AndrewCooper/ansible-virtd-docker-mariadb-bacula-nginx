#!/bin/bash
set -e

SVN_BASE_DIR=/var/lib/svn
IMPORT_EXPORT_PATH=/tmp/import_export

SVN_HOSTNAME=${SVN_HOSTNAME:=svn.example.com}
LDAP_BIND_PW=${LDAP_BIND_PW:=novatech}

# ************************************************************
# Options passed to the docker container to run scripts
# ************************************************************
# svn    : Starts apache running. This is the containers default
# backup : archives the svn repositories into the IMPORT_EXPORT_PATH
# import : import and create svn repositories from arguments and the IMPORT_EXPORT_PATH

case ${1} in
    svn)
        echo >&2 "Adding SVN repositories:"
        # Create apache config entries for each available repository
        repo_conf_dir=/etc/apache2/sites-available/dav_svn
        [[ -e ${repo_conf_dir} ]] && \
            rm -rf ${repo_conf_dir}
        mkdir -p ${repo_conf_dir}
        svn_repos="$(cd ${SVN_BASE_DIR};ls -1)"
        for repo_path in ${svn_repos} ; do
            if [[ ! -f ${repo_path}/format ]]; then
                echo >&2 "  ==> <SKIPPED>    ${repo_path}"
                continue
            fi
            repo_name=$(basename ${repo_path})
            echo >&2 "  ==> [${repo_name}]    ${repo_path}"
            cat << EOF > ${repo_conf_dir}/${repo_name}.conf
<Location /${repo_name}>
    DAV svn
    SVNPath "${SVN_BASE_DIR}/${repo_name}"
    AuthType Basic
    AuthBasicProvider ldap
    AuthName "svn repository"
    AuthLDAPURL \${LDAP_URL}
    AuthLDAPBindAuthoritative off
    AuthLDAPSearchAsUser on
    AuthLDAPCompareAsUser on
    AuthLDAPBindDN \${LDAP_BIND_DN}
    AuthLDAPBindPassword \${LDAP_BIND_PW}
    AuthLDAPGroupAttribute memberUid
    AuthLDAPGroupAttributeIsDN off
    <RequireAll>
        Require valid-user
        <RequireAny>
            Require ldap-group ${LDAP_GROUP_DN}
            Require ldap-group cn=${repo_name},${LDAP_GROUP_DN}
        </RequireAny>
    </RequireAll>
</Location>
EOF
        done
        chown -R www-data:www-data ${SVN_BASE_DIR}
        # Apache gets grumpy about PID files pre-existing
        rm -f /var/run/apache2/apache2.pid
        # Start apache
        exec apache2-foreground
        ;;

    backup)
        # commands export the SVN repositories for backup
        for repo_path in ${SVN_BASE_DIR}/*
        do
            [[ ! -f ${repo_path}/format ]] && continue
            repo_name=$(basename ${repo_path})
            [[ -f ${IMPORT_EXPORT_PATH}/${repo_name}.svndump.gz ]] && \
                rm -f ${IMPORT_EXPORT_PATH}/${repo_name}.svndump.gz
            /usr/bin/svnadmin dump ${repo_path} | gzip -9 > \
                ${IMPORT_EXPORT_PATH}/${repo_name}.svndump.gz
        done
        ;;

    hotcopy)
        # Archive SVN repositories with hotcopy
        for repo_path in ${SVN_BASE_DIR}/*
        do
            [[ ! -f ${repo_path}/format ]] && continue
            repo_name=$(basename ${repo_path})
            /usr/bin/svnadmin hotcopy --incremental --clean-logs "${repo_path}" "${IMPORT_EXPORT_PATH}/${repo_name}"
            /usr/bin/svnadmin verify --quiet "${IMPORT_EXPORT_PATH}/${repo_name}"
        done
        ;;
    restore)
        # Import hotcopy archived SVN repositories
        for src_path in ${IMPORT_EXPORT_PATH}/* ; do
            [[ ! -e ${src_path} ]] && continue
            repo_name=$(basename ${src_path})
            /usr/bin/svnadmin hotcopy --incremental --clean-logs "${src_path}" "${SVN_BASE_DIR}/${repo_name}"
            /usr/bin/svnadmin verify --quiet "${SVN_BASE_DIR}/${repo_name}"
        done
        # change permissions on svn repositories
        chown -R www-data:www-data ${SVN_BASE_DIR}
        ;;
    import)
        # ignore first argument and get list of repositories to create
        shift
        SVN_REPOSITORIES=(${*})
        # make certain the SVN directory exists
        [[ ! -d ${SVN_BASE_DIR} ]] && mkdir -p ${SVN_BASE_DIR}
        # Create SVN repositories
        for repo_name in ${SVN_REPOSITORIES[*]} ; do
            [[ ! -f ${SVN_BASE_DIR}/${repo_name}/format ]] && \
                svnadmin create --fs-type=fsfs ${SVN_BASE_DIR}/${repo_name}
        done
        # Import svndump archived SVN repositories
        for filename in ${IMPORT_EXPORT_PATH}/*.svndump.gz ; do
            [[ ! -e ${filename} ]] && continue
            repo_name=$(basename ${filename} | sed -e 's/\.svndump\.gz//')
            [[ -d ${SVN_BASE_DIR}/${repo_name} ]] && \
                rm -rf ${SVN_BASE_DIR}/${repo_name}
            /usr/bin/svnadmin create ${SVN_BASE_DIR}/${repo_name}
            /bin/gunzip --stdout ${filename} | \
                /usr/bin/svnadmin load ${SVN_BASE_DIR}/${repo_name}
        done
        # change permissions on svn repositories
        chown -R www-data:www-data ${SVN_BASE_DIR}
        ;;

    *)
        # run some other command in the docker container
        exec "$@"
        ;;
esac
