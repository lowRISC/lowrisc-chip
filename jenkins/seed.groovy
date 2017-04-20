
// pre-defined variables:
//  groupName      : github group name, default "lowrisc"
//  projectName    : project name, default "lowrisc-chip"
//  branchName     : branch name

// do not change the definition of these variables
def testJobName = "${projectName}/${branchName}/${projectName}-${branchName}-test"
def toolJobName = "${projectName}/${branchName}/${projectName}-${branchName}-tool"

matrixJob(testJobName) {

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

# build fesvr
cd $TOP/riscv-tools/riscv-fesvr
mkdir -p build
cd build
../configure --prefix=$RISCV
make > build.log
make install >> build.log

# build riscv-isa-sim
cd $TOP/riscv-tools/riscv-isa-sim
mkdir -p build
cd build
../configure --prefix=$RISCV --with-fesvr=$RISCV
make > build.log
make install >> build.log

# build riscv-gnu-toolchain
cd $TOP/riscv-tools/riscv-gnu-toolchain
mkdir -p build
cd build
../configure --prefix=$RISCV
make > build.log
make linux >> build.log

# build verilator
export VERILATOR_ROOT=$TOP/veri
cd $TOP
if [ ! -d $TOP/verilator ]; then
   git clone http://git.veripool.org/git/verilator $TOP/verilator
fi
cd $TOP/verilator
git pull origin
autoconf && ./configure --prefix=$VERILATOR_ROOT
make > build.log
make install >> build.log
if [ ! -e $VERILATOR_ROOT/include ]; then
   ln -s share/verilator/include $VERILATOR_ROOT/include
   ln -s ../share/verilator/bin/verilator_includer $VERILATOR_ROOT/bin/verilator_includer
fi
export PATH=$PATH:$VERILATOR_ROOT/bin

# run the regression test
cd $TOP/vsim
make CONFIG=$CONFIG $TEST_CASE

    ''')

  }

  // notify author if anything get wrong
  publishers {
    mailer('', true, true)
  }

}