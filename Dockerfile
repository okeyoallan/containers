FROM debian:stable

LABEL  maintainer "Okeyo Allan, <okeyoallan8@gmail.com>" \
                  "Joyce Wangari, <wangarijoyce.jw@gmail.com>" \
       description "Variant calling pipeline with GATK4" \
       version "1.0"

# package required dependencies
RUN apt-get update --fix-missing -qq && apt-get install -y -q \
    curl \
    wget \
    locales \
    libncurses5-dev \
    libncursesw5-dev \
    build-essential \
    pkg-config \
    zlib1g-dev \
    bzip2 \
    && apt-get clean \
    && apt-get purge \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN apt-get update && apt-get install -y \
        build-essential \
        curl \
        git \
        libbz2-dev \
        libcurl4-openssl-dev \
        libgsl0-dev \
        liblzma-dev \
        libncurses5-dev \
        libperl-dev \
        libssl-dev \
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*


# download java
ENV JAVA_PKG=https://download.oracle.com/java/17/latest/jdk-17_linux-x64_bin.tar.gz \
      JAVA_HOME=/usr/java/jdk-17

RUN set -eux; \
      JAVA_SHA256=$(curl "$JAVA_PKG".sha256) ; \
      curl --output /tmp/jdk.tgz "$JAVA_PKG" && \
      echo "$JAVA_SHA256 */tmp/jdk.tgz" | sha256sum -c; \
      mkdir -p "$JAVA_HOME"; \
      tar --extract --file /tmp/jdk.tgz --directory "$JAVA_HOME" --strip-components 1

# Install samtools
# RUN wget https://github.com/samtools/samtools/releases/download/1.9/samtools-1.9.tar.bz2 && \
#       tar jxf samtools-1.9.tar.bz2 && \
#       rm samtools-1.9.tar.bz2 && \
#       cd samtools-1.9 && \
#       ./configure --prefix $(pwd) && \
#       make \
##      make install


# ENV PATH=${PATH}:/usr/src/samtools-1.9

# Install bcftools
# RUN wget https://github.com/samtools/bcftools/releases/download/1.14/bcftools-1.14.tar.bz2 && \
#       tar -xf bcftools-1.14.tar.bz2 && \
#       cd bcftools-1.14 && \
#       ./configure --prefix=/bin/ && \
#       make && \
#       make install

# Install htslib
# RUN wget https://github.com/samtools/htslib/releases/download/1.14/htslib-1.14.tar.bz2 | tar -xf htslib-1.14.tar.bz2 && \
#       cd htslib-1.14 && \
#       ./configure --prefix=/bin && \
#       make && make install

# Install vcftools
# RUN wget https://sourceforge.net/projects/vcftools/files/vcftools_0.1.13.tar.gz/download | tar -xzf vcftools_0.1.13.tar.gz \
#       rm vcftools_0.1.13.tar.gz && \
#       cd vcftools_0.1.13 && \
#       ./configure --prefix=/bin/ && \
#       make && \
#       make install

USER root

WORKDIR /tmp
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

# installing miniconda
RUN wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh

# install in batch (silent) mode, does not edit PATH or .bashrc or .bash_profile
# -p path
# -f force
RUN bash Miniconda3-latest-Linux-x86_64.sh -b

ENV PATH=/root/miniconda3/bin:${PATH}

#RUN source /root/.bashrc
#RUN source /root/.bash_profile

RUN conda update -y conda
RUN conda list
RUN conda install -y numpy \
                     matplotlib \
                     pandas

RUN conda install -y jupyter notebook

# install zip utilities
RUN conda install -c conda-forge zip
# Install BWA
LABEL base.image="biocontainers:latest"
LABEL version="2"
LABEL software="bwa"
LABEL software.version="0.7.17"
LABEL about.summary="Burrow-Wheeler Aligner for pairwise alignment between DNA sequences"
LABEL about.home="http://bio-bwa.sourceforge.net/"
LABEL about.documentation="http://bio-bwa.sourceforge.net/"
LABEL license="http://bio-bwa.sourceforge.net/"
LABEL about.tags="Genomics"


RUN conda install -c bioconda bwa


CMD ["bwa"]



# Install FastQC
RUN conda install -c bioconda fastqc



# Install GATK4
RUN conda install -c bioconda gatk4

# Install trimmomatic
RUN conda install -c bioconda trimmomatic

#Install SNPeff
RUN conda install -c bioconda snpeff
RUN conda update snpeff


RUN useradd --create-home --shell /bin/bash ubuntu && \
  chown -R ubuntu:ubuntu /home/ubuntu


CMD ["/bin/bash"]
