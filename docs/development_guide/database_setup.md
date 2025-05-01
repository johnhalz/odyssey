# Database Setup

Odyssey uses a Postgres database to store data. Currently, it is recommended to use Docker to set up a Postgres database. You can use the following command to create a Postgres database in Docker:

``` bash
docker run --name odyssey -e POSTGRES_PASSWORD=odysseypassword -d -p 5432:5432 postgres
```

You can set the password to the database by setting the `POSTGRES_PASSWORD` field.

!!! note

    If you change the value of `POSTGRES_PASSWORD`, you will also need to edit this value in the `Sources/odyssey/configure.swift` file (lines 13 - 16).

Run the following command to ensure that all of the necessary migrations have been made before starting the server:

``` bash
swift run odyssey migrate
```


Now that you have your database, you can move onto setting up your [python development environment](./python_setup.md)!
