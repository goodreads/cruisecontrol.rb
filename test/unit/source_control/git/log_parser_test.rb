require 'test_helper'

module SourceControl
  class Git::LogParserTest < Test::Unit::TestCase

SIMPLE_LOG_ENTRY = <<EOF
commit e51d66aa4f708fff1c87eb9afc9c48eaa8d5ffce
tree 913027773a63829c82eeb8b626949436b216c857
parent bb52b2f82fea03b7531496c77db01f9348edbbdb
author Alexey Verkhovsky <alexey.verkhovsky@gmail.com> 1209921867 -0600
committer Alexey Verkhovsky <alexey.verkhovsky@gmail.com> 1209921867 -0600

    a comment
EOF

BIGGER_LOG_ENTRY = <<EOF
commit d8f6735bcf7d2aa4a46572109d4e091a5d0e1497
tree 06f8ce9a102edb2ca96bba58f02e710f62af63df
parent 5c881c8da857dee2735349c5a36f1f525a347652
author Scott Tamosunas and Brian Jenkins <bob-development@googlegroups.com> 1224202833 -0700
committer Scott Tamosunas and Brian Jenkins <bob-development@googlegroups.com> 1224202833 -0700

    improved rake cruise messags.

 iphone/Rakefile |    3 ++-
 1 files changed, 2 insertions(+), 1 deletions(-)

commit 5c881c8da857dee2735349c5a36f1f525a347652
tree 1a3bcfaa37a254e84f0956bedfa250e6485ee04c
parent d8120fc9372c95dd521bb77d02396c53019c4996
parent ffebfacce8baee80f9f03a2abeea8cdb9dcc7701
author Scott Tamosunas and Brian Jenkins <bob-development@googlegroups.com> 1224202700 -0700
committer Scott Tamosunas and Brian Jenkins <bob-development@googlegroups.com> 1224202700 -0700

    renamed "Unit Test" target to "UnitTest" for developer sanity.
    fixed iphone cruise Rakefile

 iphone/Rakefile                            |    2 +-
 iphone/ibob/ibob.xcodeproj/pivotal.pbxuser | 2009 +++-------------------------
 iphone/ibob/ibob.xcodeproj/project.pbxproj |  Bin 26641 -> 26654 bytes
 6 files changed, 273 insertions(+), 1875 deletions(-)
EOF

ENCODING_SPECIFIED_LOG_ENTRY = <<EOF
commit e51d66aa4f708fff1c87eb9afc9c48eaa8d5ffce
tree 913027773a63829c82eeb8b626949436b216c857
parent bb52b2f82fea03b7531496c77db01f9348edbbdb
author Alexey Verkhovsky <alexey.verkhovsky@gmail.com> 1209921867 -0600
committer Alexey Verkhovsky <alexey.verkhovsky@gmail.com> 1209921867 -0600
encoding ISO-8859-1

    a comment
EOF

GPG_SIGNED_LOG_ENTRY = <<EOF
commit ff46dbbecd1afb257686aef32fd9e0f322dedbaf
tree 35e5c4b9d9ce42caf26cbf13e61a9f92ab45ee55
parent 237db9cb5eb2e88dc886d181be7b513cec78c7d6
author Jonathon Ramsey <jonathon.ramsey@gmail.com> 1372956253 +0100
committer Jonathon Ramsey <jonathon.ramsey@gmail.com> 1372956253 +0100
gpgsig -----BEGIN PGP SIGNATURE-----
 Version: GnuPG/MacGPG2 v2.0.18 (Darwin)
 Comment: GPGTools - http://gpgtools.org

 iQEcBAABAgAGBQJR1aZeAAoJEP70U8ILrBbLzfMH/ArvQN6CWvFDxbqtJMjjpWA6
 uaHzn2aJZJCLPlrcPJc5HWzXDyvmiVazGQz0hMvJAPeim6BAt2a3DP2c7Epz1P3B
 xY1qrR6cS4cxMzc50xis1WtGrqDa76NrU2mU+ygDAuUskArI/I4VSf8nZaMlPSOq
 UlxF1OC2xh14xZCLNoN/qJ867wYHinkvEtX3e63qup+H/Skm5bdvOYtJ77GqEKSV
 4M+IoH5ydZ805kwT3ELs2ued7osDyGGvV2MNd/CRVczultppoHDuP0hj7fk2+6HQ
 QN/arrcP6ki+xW4RDJb+LzHw7LCeSzA3sHdUnjmz6UNTOkriZYuYNwSW5BFdnME=
 =pZ6o
 -----END PGP SIGNATURE-----

    Updated version to 4.0.1

 VERSION |    2 +-
 1 files changed, 1 insertions(+), 1 deletions(-)
EOF

    def test_parse_should_work
      expected_revision = Git::Revision.new(
                              :number => 'e51d66aa4f708fff1c87eb9afc9c48eaa8d5ffce',
                              :author => 'Alexey Verkhovsky <alexey.verkhovsky@gmail.com>',
                              :time => Time.at(1209921867))
      revisions = Git::LogParser.new.parse(SIMPLE_LOG_ENTRY.split("\n"))
      assert_equal [expected_revision], revisions

      assert_equal expected_revision.number, revisions.first.number
      assert_equal expected_revision.author, revisions.first.author
      assert_equal expected_revision.time, revisions.first.time
    end

    def test_should_split_into_separate_revisions
      revisions = Git::LogParser.new.parse(BIGGER_LOG_ENTRY.split("\n"))
      assert_equal 2, revisions.size

      revision = revisions[1]
      assert_equal "5c881c8da857dee2735349c5a36f1f525a347652", revision.number
      assert_equal "renamed \"Unit Test\" target to \"UnitTest\" for developer sanity.\nfixed iphone cruise Rakefile",
                   revision.message
      assert_equal ["iphone/Rakefile                            |    2 +-",
                    "iphone/ibob/ibob.xcodeproj/pivotal.pbxuser | 2009 +++-------------------------",
                    "iphone/ibob/ibob.xcodeproj/project.pbxproj |  Bin 26641 -> 26654 bytes"],
                   revision.changeset
      assert_equal "6 files changed, 273 insertions(+), 1875 deletions(-)", revision.summary
    end

    def test_parse_line_should_recognize_author
      parser = Git::LogParser.new
      author, time = parser.send(:read_author_and_time, "author Alexey Verkhovsky <alexey.verkhovsky@gmail.com> 1209921867 -0600")
      assert_equal 'Alexey Verkhovsky <alexey.verkhovsky@gmail.com>', author
      assert_equal Time.at(1209921867), time
    end

    def test_parse_line_should_regonize_and_discard_encoding
      Git::LogParser.new.parse ENCODING_SPECIFIED_LOG_ENTRY.split "\n"
    end

    def test_parsing_gpg_signed_log_entry
      revisions = Git::LogParser.new.parse(GPG_SIGNED_LOG_ENTRY.split("\n"))
      expected_revision = Git::Revision.new(
                              :number => 'ff46dbbecd1afb257686aef32fd9e0f322dedbaf',
                              :author => 'Jonathon Ramsey <jonathon.ramsey@gmail.com>',
                              :time => Time.at(1372956253))
      assert_equal [expected_revision], revisions
      revision = revisions.first

      assert_equal expected_revision.number, revision.number
      assert_equal expected_revision.author, revision.author
      assert_equal expected_revision.time, revision.time
      assert_equal ["VERSION |    2 +-"], revision.changeset
      assert_equal "1 files changed, 1 insertions(+), 1 deletions(-)", revision.summary
    end
  end
end
