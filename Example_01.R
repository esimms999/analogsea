install.packages("analogsea")
library("analogsea")

# Get a list of all existing droplets on my Digital Ocean account.
droplets()

# Create a droplet named "Eric_RStudio" with Ubuntu Server 20.04 with RStudio
# and tidyverse available.
my_droplet_name <- "Eric-RStudio"
my_droplet <- droplet_create(name=my_droplet_name, image="rstudio-20-04")


# Get info about this new droplet
as.droplet(my_droplet_name)

# Create two userids ("Eric", "Ben") each with a default password, which
# the user should change once they logon: terminal window and
# use the 'passwd' command.
users <- list(
  user = c("eric", "ben"),
  password = c("ericpass", "benpass")
)

for (i in seq_along(users$user)) {
  ubuntu_create_user(my_droplet_name, users$user[i], users$password[i], keyfile = "~/.ssh/id_rsa")
}

# Go test out the login.
cat("Go to: ", paste0(droplet_ip(as.droplet(my_droplet_name)), ":8787\n"))

# Shut down a droplet
droplet_shutdown(my_droplet_name)

# Delete a droplet
droplet_delete(my_droplet_name)

