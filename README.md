# Dialectica Compilation Environment

Docker image to build docker containers with the necessary tools to compile Dialectica articles.


## Usage

A docker-compose file is provided to run the container. 
Before you can use docker compose, you need to set up environment variables, like so:

- Copy the '.env.template' file in this directory to a new file called '.env' and then replace the value of the variables inside. These values will depend on your specific set up and Operating System:
    + `DLTC_WORKHOUSE_DIRECTORY` needs to have as a value, between quotes, the full path to the dltc-workhouse folder (the one in Dropbox) between quotes
        - For example, "/home/username/Dropbox/dltc-workhouse" for Linux, for Mac "/Users/username/Dropbox/dltc-workhouse" and "C:\Users\username\Dropbox\dltc-workhouse" for Windows
    + `HOST_USER` needs to have as a value, between quotes, the name of the user in your computer 
        - For example, "alebg"
