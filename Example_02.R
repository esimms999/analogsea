library("analogsea")
library("future")
library("tidyverse")

my_droplet_name <- "Eric-Docker"
my_droplet <- droplet_create(name=my_droplet_name, image="docker-20-04")

droplets()

as.droplet(my_droplet_name) %>% docklet_pull("rocker/tidyverse")

# Public IP for droplet(s); this can also be a vector of IP addresses
ip <- droplet_ip(as.droplet(my_droplet_name))

# Path to private SSH key that matches key uploaded to DigitalOcean
ssh_private_key_file <- "~/.ssh/id_rsa"

# Connect and create a cluster
cl <- makeClusterPSOCK(
  ip,

  # User name; DigitalOcean droplets use root by default
  user = "root",

  # Use private SSH key registered with DigitalOcean
  rshopts = c(
    "-o", "StrictHostKeyChecking=no",
    "-o", "IdentitiesOnly=yes",
    "-i", ssh_private_key_file
  ),

  # Command to run on each remote machine
  # The script loads the tidyverse Docker image
  # --net=host allows it to communicate back to this computer
  rscript = c("sudo", "docker", "run", "--net=host",
              "rocker/tidyverse", "Rscript"),

  # These are additional commands that are run on the remote machine.
  # At minimum, the remote machine needs the future library to work—installing furrr also installs future.
  rscript_args = c(
    # Create directory for package installation
    "-e", shQuote("local({p <- Sys.getenv('R_LIBS_USER'); dir.create(p, recursive = TRUE, showWarnings = FALSE); .libPaths(p)})"),
    # Install furrr and future
    "-e", shQuote("if (!requireNamespace('furrr', quietly = TRUE)) install.packages('furrr')")
  ),

  # Actually run this stuff. Set to TRUE if you don't want it to run remotely.
  dryrun = FALSE
)

plan(cluster, workers = cl)

# Verify that commands run remotely by looking at the name of the remote
# Create future expression; this doesn't run remotely yet
remote_name %<-% {
  Sys.info()[["nodename"]]
}

# Run remote expression and see that it's running inside Docker, not locally
remote_name

# Eric: what is local name?
local_name <- Sys.info()[["nodename"]]
local_name

# See how many CPU cores the remote machine has
n_cpus %<-% {parallel::detectCores()}
n_cpus

# See how many CPU cores the local machine has
n_local_cpus <- {parallel::detectCores()}
n_local_cpus

# Do stuff with data locally
top_5_worlds <- starwars %>%
  filter(!is.na(homeworld)) %>%
  count(homeworld, sort = TRUE) %>%
  slice(1:5) %>%
  mutate(homeworld = fct_inorder(homeworld, ordered = TRUE))

# Create plot remotely, just for fun
homeworld_plot %<-% {
  ggplot(top_5_worlds, aes(x = homeworld, y = n)) +
    geom_bar(stat = "identity") +
    labs(x = "Homeworld", y = "Count",
         title = "Most Star Wars characters are from Naboo and Tatooine",
         subtitle = "It really is a Skywalker/Amidala epic")
}

# Run the command remotely and show plot locally
# Note how we didn't have to load any data on the remote machine. future takes
# care of all of that for us!
homeworld_plot



# -------------
# Shut down a droplet
droplet_shutdown(my_droplet_name)

# Delete a droplet
droplet_delete(my_droplet_name)
