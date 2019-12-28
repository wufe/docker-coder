FROM codercom/code-server:v2
LABEL maintainer="simone.bembi@gmail.com"

USER root

RUN apt-get update && \
	apt-get install -y zsh gnupg gawk translate-shell gcc && \
	sh -c "$(wget -O- https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" "" --unattended && \
	curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
	echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
	apt-get update && \
	apt-get install -y yarn && \
    yarn global add typescript && \
    yarn global add parcel && \
	mkdir -p /opt/go && \
	wget https://dl.google.com/go/go1.13.4.linux-amd64.tar.gz -O go.tar.gz && \
	tar -xvf go.tar.gz && \
	mv go /usr/local && \
	echo "\nexport GOROOT=/usr/local/go" >> /home/coder/.zshrc && \
	echo "export GOPATH=\$HOME/Go" >> /home/coder/.zshrc && \
	echo "export PATH=\$GOPATH/bin:\$GOROOT/bin:\$PATH" >> /home/coder/.zshrc && \
	/usr/local/go/bin/go version && \
	/usr/local/go/bin/go env && \
	rm -rf /opt/go

RUN git config --global credential.helper store

ENV \
    # Enable detection of running in a container
    DOTNET_RUNNING_IN_CONTAINER=true \
    # Enable correct mode for dotnet watch (only mode supported in a container)
    DOTNET_USE_POLLING_FILE_WATCHER=true \
    # Skip extraction of XML docs - generally not useful within an image/container - helps performance
    NUGET_XMLDOC_MODE=skip \
    # PowerShell telemetry for docker image usage
    POWERSHELL_DISTRIBUTION_CHANNEL=PSDocker-DotnetCoreSDK-Ubuntu-18.04

# Install .NET CLI dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libc6 \
        libgcc1 \
        libgssapi-krb5-2 \
        libicu60 \
        libssl1.1 \
        libstdc++6 \
        zlib1g \
    && rm -rf /var/lib/apt/lists/*

# Install .NET Core SDK
RUN dotnet_sdk_version=3.1.100 \
    && curl -SL --output dotnet.tar.gz https://dotnetcli.azureedge.net/dotnet/Sdk/$dotnet_sdk_version/dotnet-sdk-$dotnet_sdk_version-linux-x64.tar.gz \
    && dotnet_sha512='5217ae1441089a71103694be8dd5bb3437680f00e263ad28317665d819a92338a27466e7d7a2b1f6b74367dd314128db345fa8fff6e90d0c966dea7a9a43bd21' \
    && echo "$dotnet_sha512 dotnet.tar.gz" | sha512sum -c - \
    && mkdir -p /usr/share/dotnet \
    && tar -ozxf dotnet.tar.gz -C /usr/share/dotnet \
    && rm dotnet.tar.gz \
    && ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet \
    # Trigger first run experience by running arbitrary cmd
    && dotnet help

# Install PowerShell global tool
RUN dotnet tool install --global PowerShell \
	&& dotnet nuget locals all --clear

USER coder