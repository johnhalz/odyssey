# Running Server & Creating an Admin Account

## Running Server Locally

Before running the server, make sure that you have a Docker image of Postgres setup and running with the correct credentials and migrations (see the [database setup guide](./database_setup.md) for this)

You can run the server with the command:

``` sh
swift run odyssey
```

This command will output the address from which you can access Odyssey on your browser. For local deployments, this will most likely be http://127.0.0.1:8000.
