FROM debian:stable

LABEL  maintainer "Okeyo Allan, <okeyoallan8@gmail.com>" \
                  "Joyce Wangari, <wangarijoyce.jw@gmail.com>" \
       description "Variant calling pipeline with GATK4" \
       version "1.0"

USER root

WORKDIR /tmp

# package required dependencies
RUN apt-get update --fix-missing -qq && apt-get install -y -q \
    curl \
    wget \
    zip \
    locales \
    git \
    libbz2-dev \
    libcurl4-openssl-dev \
    libgsl0-dev \
    liblzma-dev \
    libncurses5-dev \
    libperl-dev \
    libssl-dev \
    libncurses5-dev \
    libncursesw5-dev \
    build-essential \
    pkg-config \
    zlib1g-dev \
    bzip2 \
    && apt-get clean \
    && apt-get purge \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# download java
ENV JAVA_PKG=https://download.oracle.com/java/17/latest/jdk-17_linux-x64_bin.tar.gz \
      JAVA_HOME=/usr/java/jdk-17
RUN set -eux; \
      JAVA_SHA256=$(curl "$JAVA_PKG".sha256) ; \
      curl --output /tmp/jdk.tgz "$JAVA_PKG" && \
      echo "$JAVA_SHA256 */tmp/jdk.tgz" | sha256sum -c; \
      mkdir -p "$JAVA_HOME"; \
      tar --extract --file /tmp/jdk.tgz --directory "$JAVA_HOME" --strip-components 1

# Install Samtools, Vcftools, Bcftools
ARG htsversion=1.9
RUN curl -L https://github.com/samtools/htslib/releases/download/${htsversion}/htslib-${htsversion}.tar.bz2 | tar xj && \
    (cd htslib-${htsversion} && ./configure --enable-plugins --with-plugin-path='$(libexecdir)/htslib:/usr/libexec/htslib' && make install) && \
    ldconfig && \
    curl -L https://github.com/samtools/samtools/releases/download/${htsversion}/samtools-${htsversion}.tar.bz2 | tar xj && \
    (cd samtools-${htsversion} && ./configure --with-htslib=system && make install) && \
    curl -L https://github.com/samtools/bcftools/releases/download/${htsversion}/bcftools-${htsversion}.tar.bz2 | tar xj && \
    (cd bcftools-${htsversion} && ./configure --enable-libgsl --enable-perl-filters --with-htslib=system && make install) && \
    git clone --depth 1 git://github.com/samtools/htslib-plugins && \
    (cd htslib-plugins && make PLUGINS='hfile_cip.so hfile_mmap.so' install)

# add ps command 
RUN apt-get update && apt install -y procps g++ && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* 
# Install vt from github
#RUN git clone https://github.com/atks/vt.git \
 #   && cd vt \
  #  && git submodule update --init --recursive \
   # && make 
    
# RUN  git pull \
 
 # Install and compile miniconda3
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV PATH /opt/conda/bin:$PATH    
ENV CONDA_DIR /opt/conda
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p /opt/conda && \
    rm ~/miniconda.sh && \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda activate base" >> ~/.bashrc
    

# Put conda in path so we can use conda activate
ENV PATH=$CONDA_DIR/bin:$PATH
RUN  echo "conda activate base" >> ~/.bashrc

# Install FastQC
RUN conda clean --all --yes && \
    conda install -c bioconda fastqc

# Install GATK4
RUN conda clean --all --yes
RUN conda install -c bioconda gatk4

# Install Trimmomatic
RUN conda clean --all --yes && \
    conda install -c bioconda trimmomatic

#Install SNPeff
RUN conda clean --all --yes && \
    conda install -c bioconda snpeff

# Installing vcftools
RUN wget https://github.com/vcftools/vcftools/releases/download/v0.1.16/vcftools-0.1.16.tar.gz && \
    tar -xvf vcftools-0.1.16.tar.gz && \
    cd vcftools-0.1.16 && \
    ./configure && \
    make && \
    make install
 # Install BWA   
RUN conda clean --all --yes && \
    conda install -c bioconda bwa
    
# Install Multiqc
RUN conda clean --all --yes && \
    pip install multiqc
    
# Install vt tool
RUN conda clean --all --yes && \
conda install -c bioconda vt

RUN conda install -c bioconda/label/cf201901 vt 
RUN conda update vt


# update conda environment 
RUN conda update --all

RUN useradd --create-home --shell /bin/bash ubuntu && \
  chown -R ubuntu:ubuntu /home/ubuntu


CMD ["/bin/bash"]
