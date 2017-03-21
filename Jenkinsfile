node {
    stage("Checkout") {
        checkout([
            $class: 'GitSCM',
            branches: [[name: 'refs/heads/master']],
            doGenerateSubmoduleConfigurations: false,
            extensions: [
                [
                    $class: 'CloneOption',
                    depth: 0,
                    noTags: true,
                    shallow: true
                ]
            ],
            submoduleCfg: [],
            userRemoteConfigs: scm.userRemoteConfigs
        ])

    }

    if (env.BRANCH_NAME.equals("master")) {
        stage('Build binary') {
            sh("make binary")
        }

        stage('Build image') {
            sh("docker pull debian:jessie")
            sh("make build")
        }

        stage('Push image to registry') {
            sh("make release tag")
        }
    }
}
