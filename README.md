<p align="center" style="margin-bottom: 0px !important;">
  <img width="200" src="docs/img/logo.svg" alt="Odyssey Logo" align="center">
</p>
<h1 align="center" style="margin-top: 0px;">Odyssey</h1>

<p align="center" >Modern cloud architecture for hardware production and testing</p>
<p align="center" >💧 A project built with the Vapor web framework</p>

[Link to Documentation](https://johnhalz.github.io/odyssey/)

## Running the Project Locally

To build the project using the Swift Package Manager, run the following command in the terminal from the root of the project:
```bash
swift build
```

To run the project and start the server, use the following command:
```bash
swift run
```

To run the project and execute migrations, use the following command:
``` bash
swift run odyssey migrate
```

To undo a migration on your database, run `migrate` with the `--revert` flag.
``` bash
swift run odyssey migrate --revert
```

To execute tests, use the following command:
```bash
swift test
```

### Setting Up Postgres in Docker
Run the following commands to create a new docker container with Postgres:
```shell
docker run --name odyssey -e POSTGRES_PASSWORD=odysseypassword -d -p 5432:5432 postgres
```
