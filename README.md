# Dialectica Compilation Environment

Docker image to build docker containers with the necessary tools to compile Dialectica articles.


## Usage

A docker-compose file is provided to run the container. 
Before you can use docker compose, you need to set up environment variables, like so:

- Copy the '.env.template' file in this directory to a new file called '.env' and then replace the value of the variables inside. These values will depend on your specific set up and Operating System:
    + `DLTC_WORKHOUSE_DIRECTORY` needs to have as a value, between quotes, the full path to the dltc-workhouse folder (the one in Dropbox) between quotes
        - Example for Windows: in Windows, the path has to be written in Unix-style, changing the backwards "\\" to forward "/". That is, IF the path to your folder is "C:\Users\ `your_username`\Dropbox\philosophie-ch\dltc-workhouse" THEN you need to write "C:/Users/ `your_username`/Dropbox/philosophie-ch/dltc-workhouse"
        - Example for Mac: "/Users/ `your_username`/Dropbox/philosophie-ch/dltc-workhouse"
        - Example for Linux: "/home/ `your_username`/Dropbox/philosophie-ch/dltc-workhouse"
