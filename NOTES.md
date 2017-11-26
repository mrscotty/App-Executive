This package is managed with Minilla. The common tasks are:

    minil new     - Create a new dist
    minil test    - Run test cases
    minil dist    - Make your dist tarball
    minil install - Install your dist
    minil release - Release your dist to CPAN
    minil run     - Run arbitrary commands against build dir

To do a test release *without* uploading to CPAN:

    FAKE_RELEASE=1 minil release - Release your dist to CPAN

For more information (see the CONFIGURATION section towards the end):

    https://metacpan.org/pod/distribution/Minilla/lib/Minilla/Tutorial.pod
