const githubActionTemplate = r'''
name: Branch Push

on:
  push:
    branches:
      - '**'
    paths:
      - 'lib/**'
      - 'pubspec.yaml'
      - 'pubspec.lock'

env:
  SHOREBIRD_TOKEN: ${{ secrets.SHOREBIRD_TOKEN }}

jobs:
  patch:
    name: Push patch to branch track
    runs-on: ubuntu-latest
    steps:
      - name: Git Checkout
        uses: actions/checkout@v4

      - name: Setup Java
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '17'

      - name: Setup Shorebird
        uses: shorebirdtech/setup-shorebird@v1
        with:
          cache: true

      - name: Extract branch name
        id: branch
        run: echo "name=${GITHUB_REF_NAME}" >> "$GITHUB_OUTPUT"

      - name: Read release version
        id: version
        run: |
          VERSION=$(grep '^version:' pubspec.yaml | awk '{print $2}')
          echo "version=$VERSION" >> "$GITHUB_OUTPUT"

      - name: Shorebird Patch (Android)
        run: |
          shorebird patch android \
            --track ${{ steps.branch.outputs.name }} \
            --release-version ${{ steps.version.outputs.version }} \
            --allow-native-diffs \
            --allow-asset-diffs

      - name: Shorebird Patch (iOS)
        run: |
          shorebird patch ios \
            --track ${{ steps.branch.outputs.name }} \
            --release-version ${{ steps.version.outputs.version }} \
            --allow-native-diffs \
            --allow-asset-diffs
''';
