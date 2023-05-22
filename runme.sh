#!/usr/bin/env bash

set -x # Print commands and their arguments as they are executed.
set -e # Exit immediately if a command exits with a non-zero status.

wget "https://code.quarkus.io/d?cn=code.quarkus.io" -O project.zip
unzip -o project.zip
cd code-with-quarkus

START=1
TIMES=10
PROJECT_PATH=target/code-with-quarkus-1.0.0-SNAPSHOT-native-image-source-jar/
RESULTS=../results
COMMAND="./mvnw clean package -DskipTests -Dnative -Dquarkus.native.container-build=true"

# Mandrel runs
for i in $(seq $START $TIMES)
do
    $COMMAND -Dquarkus.native.builder-image=quay.io/quarkus/ubi-quarkus-mandrel-builder-image:22.3-java17
    mkdir -p $RESULTS/mandrel-default-"$i"
    mv $PROJECT_PATH/*.json $RESULTS/mandrel-default-"$i"/
done

# Mandrel with graal JIT runs
for i in $(seq $START $TIMES)
do
    $COMMAND -Dquarkus.native.builder-image=quay.io/quarkus/ubi-quarkus-mandrel-builder-image:22.3-java17 \
      -Dquarkus.native.additional-build-args=-J-XX:+UseJVMCINativeLibrary
    mkdir -p $RESULTS/mandrel-graaljit-"$i"
    mv $PROJECT_PATH/*.json $RESULTS/mandrel-graaljit-"$i"/
done

# GraalVM CE default runs
for i in $(seq $START $TIMES)
do
    $COMMAND -Dquarkus.native.builder-image=quay.io/quarkus/ubi-quarkus-graalvmce-builder-image:22.3-java17
    mkdir -p $RESULTS/graal-default-"$i"
    mv $PROJECT_PATH/*.json $RESULTS/graal-default-"$i"/
done

# GraalVM CE runs without libgraal
for i in $(seq $START $TIMES)
do
    $COMMAND -Dquarkus.native.builder-image=quay.io/quarkus/ubi-quarkus-graalvmce-builder-image:22.3-java17 \
      -Dquarkus.native.additional-build-args=-J-XX:-UseJVMCINativeLibrary
    mkdir -p $RESULTS/graal-nolib-graal-"$i"
    mv $PROJECT_PATH/*.json $RESULTS/graal-nolib-graal-"$i"/
done

# GraalVM CE runs without libgraal (or graal)
for i in $(seq $START $TIMES)
do
    $COMMAND -Dquarkus.native.builder-image=quay.io/quarkus/ubi-quarkus-graalvmce-builder-image:22.3-java17 \
      -Dquarkus.native.additional-build-args=-J-XX:-UseJVMCINativeLibrary,-J-XX:-UseJVMCICompiler
    mkdir -p $RESULTS/graal-nolib-nograal-"$i"
    mv $PROJECT_PATH/*.json $RESULTS/graal-nolib-nograal-"$i"/
done

# merge results from different runs in one json file
jq -s '.[] |= . + {configuration:"mandrel-default"}' $RESULTS/mandrel-default-*/code-with-quarkus-1.0.0-SNAPSHOT-runner-timing-stats.json > $RESULTS/mandrel-default.json
jq -s '.[] |= . + {configuration:"mandrel-graaljit"}' $RESULTS/mandrel-graaljit-*/code-with-quarkus-1.0.0-SNAPSHOT-runner-timing-stats.json > $RESULTS/mandrel-graaljit.json
jq -s '.[] |= . + {configuration:"graal-default"}' $RESULTS/graal-default-*/code-with-quarkus-1.0.0-SNAPSHOT-runner-timing-stats.json > $RESULTS/graal-default.json
jq -s '.[] |= . + {configuration:"graal-nolib-graal"}' $RESULTS/graal-nolib-graal-*/code-with-quarkus-1.0.0-SNAPSHOT-runner-timing-stats.json > $RESULTS/graal-nolib-graal.json
jq -s '.[] |= . + {configuration:"graal-nolib-nograal"}' $RESULTS/graal-nolib-nograal-*/code-with-quarkus-1.0.0-SNAPSHOT-runner-timing-stats.json > $RESULTS/graal-nolib-nograal.json
# merge all results in a single file as an array
jq -c -r -s 'flatten' $RESULTS/*.json > $RESULTS/all.json