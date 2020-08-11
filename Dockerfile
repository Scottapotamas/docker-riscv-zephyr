FROM ubuntu:20.04

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Australia/Adelaide

# Install deps
RUN apt-get update && apt-get install -y \
	apt-utils \
	git \
	make \
	gcc \
	gcc-multilib \
	cmake \
	ninja-build \
	gperf \
	ccache \
	dfu-util \
	device-tree-compiler \
	wget \
	curl \
	libncurses5 \
	xz-utils \
	file \
	usbutils \
	screen \
	libsm6 \
	libxrandr2 \
	libxfixes3 \
	libxcursor1 \
	libxext6 \
    python3 \
    python3-dev \
    python3-pip \
	python3-wheel \
	python3-tk \
	python3-setuptools

RUN pip3 install ipython
RUN pip3 install numpy
RUN pip3 install pyelftools
RUN pip3 install west

# Get the latest zephyrproject-rtos/sdk-ng release from Github (typically ~800MB)
RUN LATEST=$(curl -sL --fail https://api.github.com/repos/zephyrproject-rtos/sdk-ng/releases/latest | grep "tag_name" | perl -pe 'if(($_)=/([0-9]+([.][0-9]+)+)/){$_.="\n"}') ; curl -vsL "https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v$LATEST/zephyr-sdk-$LATEST-setup.run" -o zephyr-sdk-setup.run

# Setup the zephyr sdk we just downloaded
RUN chmod +x zephyr-sdk-setup.run
RUN ./zephyr-sdk-setup.run -- -d ~/zephyr-sdk-latest
RUN export ZEPHYR_TOOLCHAIN_VARIANT=zephyr
RUN export ZEPHYR_SDK_INSTALL_DIR=$HOME/zephyr-sdk-latest

# Download and install the JLink tools
RUN wget -q --post-data 'accept_license_agreement=accepted&non_emb_ctr=confirmed&submit=Download+software' https://www.segger.com/downloads/flasher/JLink_Linux_x86_64.deb
RUN dpkg -i ./JLink_Linux_x86_64.deb