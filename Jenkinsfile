/**
properties([
  parameters([
    string(defaultValue: '1.0', description: 'Current version number', name: 'VERSION'),
    text(defaultValue: '', description: 'A list of changes', name: 'CHANGES'),
    booleanParam(defaultValue: false, description: 'If build should be marked as pre-release', name: 'PRERELEASE'),
    string(defaultValue: 'ayufan-rock64', description: 'GitHub username or organization', name: 'GITHUB_USER'),
    string(defaultValue: 'linux-build', description: 'GitHub repository', name: 'GITHUB_REPO'),
  ])
])
*/

node('docker && linux-build') {
  timestamps {
    wrap([$class: 'AnsiColorBuildWrapper', colorMapName: 'xterm']) {
      stage "Environment"
      checkout scm

      def environment = docker.build('build-environment:build-rock64-linux-package', 'environment')

      environment.inside("--privileged -u 0:0") {
        withEnv([
          "RELEASE=$BUILD_NUMBER"
        ]) {
          stage 'Prepare'
          sh '''#!/bin/bash
            set +xe
            git clean -ffdx -e ccache
          '''

          stage 'Package'
          sh '''#!/bin/bash
            set +xe
            make build
          '''

          if (params.GITHUB_TOKEN) {
            stage 'Upload'
            sh '''#!/bin/bash
              set +xe
              make upload
            '''
          }
        }
      }
    }
  }
}
