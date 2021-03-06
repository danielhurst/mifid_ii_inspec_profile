# encoding: utf-8
#
# Copyright 2017, Emre Erkunt
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# author: Emre Erkunt
# author: Daniel Hurst

title 'File integrity checks for *.data files in /important/files'

control 'integrity-01' do
  impact 1.0
  title 'Check for integrity of important files if they are replicated correctly'
  desc 'MiFIDD II - Sample Test 01'
  tag 'integrity'

  # Static Configuration
  numberOfHosts = 3
  redisHostKey = 'scb-demo-integrity-01-hostCount'
  redisCksumKey = 'scb-demo-integrity-01-sha256sum'
  #redisCli = 'docker exec test-redis redis-cli' # <= This is for local testing.
  redisCli = "redis-cli"
  targetDir = '/important/files'

  describe command('sha256sum').exist? do
    it { should eq true }
  end

  currentHost = `#{redisCli} incr #{redisHostKey}`
  currentHost = currentHost.strip.to_i

  # describe currentHost do
  #     it { should be <= numberOfHosts }
  # end

  output = command('find '+targetDir+' -name "*.data"').stdout
  fileList = output.split(/\r?\n/)

  fileList.each do |fileName|
    fileObj = file(fileName)

    describe fileObj do
      it { should be_file }
    end

    baseFileName = fileName # Get the file name itself, not the full path.
    redisKey = redisCksumKey + baseFileName
    redisSha256Sum = `#{redisCli} get #{redisKey}`.strip

    if redisSha256Sum == ""
      `#{redisCli} set #{redisKey} #{fileObj.sha256sum}`
    else
      describe fileObj do
        its(:sha256sum) { should eq redisSha256Sum }
      end
    end

    if currentHost >= numberOfHosts
      `#{redisCli} del #{redisKey}`
      `#{redisCli} set #{redisHostKey} 0`
    end
  end

end