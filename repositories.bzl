# Copyright 2019 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_jar")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:jvm.bzl", "jvm_maven_import_external")
load("@gapic_generator_java_properties//:dependencies.properties.bzl", "PROPERTIES")

def gapic_generator_java_repositories():
    # Import dependencies shared between Gradle and Bazel (i.e. maven dependencies)
    for name, artifact in PROPERTIES.items():
        _maybe(
            jvm_maven_import_external,
            name = name,
            strip_repo_prefix = "maven.",
            artifact = _fix_bazel_artifact_format(artifact),
            server_urls = ["https://repo.maven.apache.org/maven2/", "http://repo1.maven.org/maven2/"],
            licenses = ["notice", "reciprocal"],
        )

    # Import Bazel-only dependencies (Gradle version will import maven artifacts of same
    # version, while Bazel will depend on Bazel workspaces). The versions are shared in the
    # properties file.
    _protobuf_version = PROPERTIES["version.com_google_protobuf"]
    _maybe(
        http_archive,
        name = "com_google_protobuf",
        urls = ["https://github.com/protocolbuffers/protobuf/archive/v%s.zip" % _protobuf_version],
        strip_prefix = "protobuf-%s" % _protobuf_version,
    )

    _maybe(
        jvm_maven_import_external,
        name = "google_java_format_all_deps",
        artifact = "com.google.googlejavaformat:google-java-format:jar:all-deps:%s" % PROPERTIES["version.google_java_format"],
        server_urls = ["https://repo.maven.apache.org/maven2/", "http://repo1.maven.org/maven2/"],
        licenses = ["notice", "reciprocal"],
    )

    _maybe(
        http_archive,
        name = "bazel_skylib",
        sha256 = "bbccf674aa441c266df9894182d80de104cabd19be98be002f6d478aaa31574d",
        strip_prefix = "bazel-skylib-2169ae1c374aab4a09aa90e65efe1a3aad4e279b",
        urls = ["https://github.com/bazelbuild/bazel-skylib/archive/2169ae1c374aab4a09aa90e65efe1a3aad4e279b.tar.gz"],
    )

    _maybe(
        http_archive,
        name = "com_google_googleapis",
        strip_prefix = "googleapis-ba30d8097582039ac4cc4e21b4e4baa426423075",
        urls = [
            "https://github.com/googleapis/googleapis/archive/ba30d8097582039ac4cc4e21b4e4baa426423075.zip",
        ],
    )

    _maybe(
        http_archive,
        name = "com_google_googleapis_discovery",
        strip_prefix = "googleapis-discovery-34478e2969042ed837d33684360f1ee3be7d2f74",
        urls = [
            "https://github.com/googleapis/googleapis-discovery/archive/34478e2969042ed837d33684360f1ee3be7d2f74.zip",
        ],
    )

    _maybe(
        native.bind,
        name = "guava",
        actual = "@com_google_guava_guava//jar",
    )

    _maybe(
        native.bind,
        name = "gson",
        actual = "@com_google_code_gson_gson//jar",
    )

    _maybe(
        jvm_maven_import_external,
        name = "error_prone_annotations_maven",
        artifact = "com.google.errorprone:error_prone_annotations:2.3.2",
        server_urls = ["https://repo.maven.apache.org/maven2/", "http://repo1.maven.org/maven2/"],
        licenses = ["notice", "reciprocal"],
    )

    _maybe(
        native.bind,
        name = "error_prone_annotations",
        actual = "@error_prone_annotations_maven//jar",
    )

    _api_common_java_version = PROPERTIES["version.com_google_api_common_java"]
    _maybe(
        jvm_maven_import_external,
        name = "com_google_api_api_common",
        artifact = "com.google.api:api-common:%s" % _api_common_java_version,
        server_urls = ["https://repo.maven.apache.org/maven2/"],
    )

    # grpc-proto doesn't have releases, so we use hashes instead.
    _io_grpc_proto_prefix = "0020624375a8ee4c7dd9b3e513e443b90bc28990"  # Aug. 20, 2020.
    _maybe(
        http_archive,
        name = "io_grpc_proto",
        urls = ["https://github.com/grpc/grpc-proto/archive/%s.zip" % _io_grpc_proto_prefix],
        strip_prefix = "grpc-proto-%s" % _io_grpc_proto_prefix,
    )

def _maybe(repo_rule, name, strip_repo_prefix = "", **kwargs):
    if not name.startswith(strip_repo_prefix):
        return
    repo_name = name[len(strip_repo_prefix):]
    if repo_name in native.existing_rules():
        return
    repo_rule(name = repo_name, **kwargs)

def _fix_bazel_artifact_format(artifact_id):
    # Fix the artifact id format discrepancy between Bazel & Gradle.
    # This is relevant only when classifier is specified explicitly.
    # Bazel format:  groupId:artifactId:jar:classifier:version
    # Gradle format: groupId:artifactId:version:classifier
    ids = artifact_id.split(":")
    if len(ids) != 4:
        return artifact_id
    return "%s:%s:%s:%s:%s" % (ids[0], ids[1], "jar", ids[3], ids[2])
