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
and also [Hosts Manager](http://www.abelhadigital.com/hostsman/) or
[HostsFileEditor](https://github.com/scottlerch/HostsFileEditor) for managing Windows hosts file.

```
# Clone this repo
git clone https://github.com/riipandi/wsl-server

# Make all script executable
cd wsl-server
find . -type f -name '*.sh' -exec chmod +x {} \;
find . -type f -name '.git*' -exec rm -fr {} \;

# Run setup
sudo ./setup.sh

# As non-root:
bash userlib.sh
```

## License

This program is free software: you can distribute it and or modify it according to the license provided.
Unless specifically stated, this program is licensed under the terms of the
[MIT License](https://choosealicense.com/licenses/mit/). See the [LICENSE](./LICENSE) file for the full
license text.
