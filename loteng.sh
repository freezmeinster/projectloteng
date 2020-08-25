#!/usr/bin/env bash

CONF_PATH=~/.config/loteng.conf
BASE_PATH=~/.local/share/loteng
GIT_STORE=$BASE_PATH/store
TEMP=$BASE_PATH/temp
STAGING=$BASE_PATH/staging
NOW=$(date +%Y-%m-%d-%H-%M-%S)

prepare_base_dir(){
	if [ ! -d $TEMP ]; then
		mkdir -p $TEMP
	fi	
	if [ ! -d $STAGING ]; then
		mkdir -p $STAGING
	fi
	if [ ! -d ~/.ssh ]; then
		mkdir -p ~/.ssh
	fi
}

check_conf_found(){
	if [ -f $CONF_PATH ]; then
		. $CONF_PATH
	else
		echo "Config file $CONF_PATH not found"
		exit
	fi
}

check_git_store(){
	if [ $GIT_URL != "" ]; then
		if [ ! -d $GIT_STORE ]; then
			echo "Initialize git store"
			git clone -q $GIT_URL $GIT_STORE
		else
			echo "Git Storage ok"
		fi
	else
		echo "No GIT_URL found in $CONF_PATH"
		exit
	fi
}

run_backup(){
	cp -r ~/.ssh/* $TEMP
	cd $BASE_PATH
	tar cf - temp | xz -9ec | openssl enc -a -aes-256-cbc -salt > $GIT_STORE/sshstore.enc
	cd $GIT_STORE
	git add sshstore.enc
	git config user.name "Loteng Backup"
	git config user.email "user@loteng.mula.cloud"
	git commit -m "$NOW"
	git push origin master
}

run_restore(){
	cd $GIT_STORE
	git config user.name "Loteng Backup"
	git config user.email "user@loteng.mula.cloud"
	git pull origin master
	cd $STAGING
	rm -fr $STAGING/temp
	cat $GIT_STORE/sshstore.enc | openssl enc -a -aes-256-cbc -md sha256 -d | xz -dc | tar xf - 
	cp -f $STAGING/temp/* ~/.ssh/ 
}


# run prepare basedir for confinience
prepare_base_dir

case $1 in 
	backup)
		echo "Backuping SSH directory"
		check_conf_found
		check_git_store
		run_backup
		echo "Done"
	;;
	restore)
		echo "Restoring SSH directory"
		check_conf_found
		check_git_store
		run_restore

	;;
	*)
		echo "Usage: $0 [backup|restore]"
	;;
esac

