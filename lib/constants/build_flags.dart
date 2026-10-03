/// Build-time switch: `--dart-define=VHSFIN_VHSCOLLECTOR=true` compiles in the
/// optional VHSCollector sleeve lookup and its Settings toggle. Off by default,
/// so store builds and forks don't query vhscollector.com without permission.
const vhsCollectorBuild = bool.fromEnvironment('VHSFIN_VHSCOLLECTOR');
