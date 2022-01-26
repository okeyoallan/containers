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


# Install BWA
LABEL software="bwa"
LABEL software.version="0.7.17"
RUN wget https://sourceforge.net/projects/bio-bwa/files/bwa-0.7.17.tar.bz2 | tar xvf /tmp/bwa-0.7.17.tar.bz2 | bunzip2 /tmp/bwa-0.7.17.tar.bz2 | tar xzf /tmp/bwa-0.7.17.tar \
    && cd /tmp/bwa-0.7.17 \
    && make && make install 
   
RUN export PATH=$PATH:/tmp/bwa-0.7.17:$PATH

# Install FastQC
RUN wget https://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v0.11.9.zip | unzip /tmp/fastqc_v0.11.9.zip \
    && cd /tmp/fastqc_v0.11.9\
    && make && make install 
    
RUN export PATH=$PATH:/tmp/fastqc_v0.11.9:$PATH

# Install GATK4
RUN wget https://github.com/broadinstitute/gatk/releases/download/4.2.4.1/gatk-4.2.4.1.zip | unzip /tmp/gatk-4.2.4.1.zip \
    && cd /tmp/gatk-4.2.4.1 \
    && make && make install 
    
RUN export PATH=$PATH:/tmp/gatk-4.2.4.1:$PATH

# Install Trimmomatic
RUN wget http://www.usadellab.org/cms/uploads/supplementary/Trimmomatic/Trimmomatic-0.39.zip | unzip /tmp/Trimmomatic-0.39.zip \
    && cd /tmp/Trimmomatic-0.39 \
    && make && make install 
    
RUN export PATH=$PATH:/tmp/Trimmomatic-0.39:$PATH

#Install SNPeff
RUN wget https://snpeff.blob.core.windows.net/versions/snpEff_latest_core.zip | unzip /tmp/snpEff_latest_core.zip \
    && cd /tmp/snpEff\
    && make && make install 
    
RUN export PATH=$PATH:/tmp/snpEff:$PATH


RUN useradd --create-home --shell /bin/bash ubuntu && \
  chown -R ubuntu:ubuntu /home/ubuntu


CMD ["/bin/bash"]
