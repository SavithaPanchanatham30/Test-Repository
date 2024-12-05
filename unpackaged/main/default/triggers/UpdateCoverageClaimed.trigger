trigger UpdateCoverageClaimed on UpdateCoverageClaimed__e(after insert) {
  new UpdateCoverageClaimedHandler().run();
}