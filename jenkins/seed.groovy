
// pre-defined variables:
//  groupName      : github group name, default "lowrisc"
//  projectName    : project name, default "lowrisc-chip"
//  branchName     : branch name

// do not change the definition of these variables
def jobName = "${projectName}/${branchName}/${projectName}-${branchName}-test"

matrixJob(jobName) {

  // define the variables for matrix tests
  axes {
    text('CONFIG', 'DefaultConfig')
    text('TEST_CASE', 'run-asm-tests')
  }

  // git repo
  scm {
    git{
      remote { url("https://github.com/${groupName}/${projectName}.git") }
      branch(branchName)
      extensions {
//        wipeOutWorkspace()
        submoduleOptions {
          recursive(true)
        }
      }
    }
  }

  // current only time triggers
  triggers {
    scm('H/6 * * * *')
  }

  // the actual test script
  steps {
    shell('''

    source ./set_env.sh

    ''')

  }

  // notify author if anything get wrong
  publishers {
    mailer('ws327@cam.ac.uk', true, true)
  }

}