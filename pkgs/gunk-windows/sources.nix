{ fetchFromGitHub }:
{
  upstream = fetchFromGitHub {
    owner = "cemkod"; repo = "gunk";
    rev = "9cb7995ec4dbb982bf1c034f4499104422f1b0a9";
    hash = "sha256-PZv4iaZVhDooy2Nr15KrsD2f6x6K+Rmi99dN50VbBno=";
  };
  juce = fetchFromGitHub {
    owner = "juce-framework"; repo = "JUCE";
    rev = "4f43011b96eb0636104cb3e433894cda98243626"; # 7.0.12
    hash = "sha256-/awe6D824ZjF17xjkt0wY7dcDuS/s8KKAv1UKHxF0FM=";
  };
  aubio = fetchFromGitHub {
    owner = "aubio"; repo = "aubio";
    rev = "319186517bfc0dd5c015241c091b849f209e0483"; # 0.4.9
    hash = "sha256-RvzhB1kQNP0IbAygwH2RBi/kSyuFPAHgsiCATPeMHTo=";
  };
  # Selected master on 2026-10-17, NOT a claim about upstream's historical build.
  q = fetchFromGitHub {
    owner = "cycfi"; repo = "q";
    rev = "efe26114f39e4a78bd67c1456a25487d356fb910";
    hash = "sha256-QXL7I0UXgUhBbsncGaAkQEC0OicNUd2nhRlF5gZtJIc=";
  };
  # Exact gitlink in the selected Q commit; prevents its network fallback.
  infra = fetchFromGitHub {
    owner = "cycfi"; repo = "infra";
    rev = "62a88cab2278ac843765c986edfd4d7393ae3db2";
    hash = "sha256-Gldorla9SzBRV8jHTG02+BZZq0jd2wVkPDReewLR3aE=";
  };
}
