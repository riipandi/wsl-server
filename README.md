# Your Development Server in WSL

```
██╗    ██╗███████╗██╗       ███████╗███████╗██████╗ ██╗   ██╗███████╗██████╗
██║    ██║██╔════╝██║       ██╔════╝██╔════╝██╔══██╗██║   ██║██╔════╝██╔══██╗
██║ █╗ ██║███████╗██║       ███████╗█████╗  ██████╔╝██║   ██║█████╗  ██████╔╝
██║███╗██║╚════██║██║       ╚════██║██╔══╝  ██╔══██╗╚██╗ ██╔╝██╔══╝  ██╔══██╗
╚███╔███╔╝███████║███████╗  ███████║███████╗██║  ██║ ╚████╔╝ ███████╗██║  ██║
 ╚══╝╚══╝ ╚══════╝╚══════╝  ╚══════╝╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝╚═╝  ╚═╝
```

## Quick Start

You will need [Ubuntu WSL](https://www.microsoft.com/en-us/p/ubuntu-1804-lts/9n9tngvndl3q) installed
and also [hosts manager](http://www.abelhadigital.com/hostsman/) for managing Windows hosts file.

```
# Clone this repo
git clone https://github.com/riipandi/wsl-server

# Make all script executable
cd wsl-server ; chmod +x *.sh

# Setup the packages
sudo su -c "./setup-server.sh"

# As non-root user execute:
./setup-devlib.sh
```

## License

This program is free software: you can distribute it and or modify it according to the license provided.
Unless specifically stated, this program is licensed under the terms of the
[MIT License](https://choosealicense.com/licenses/mit/). See the [LICENSE](./LICENSE) file for the full
license text.
