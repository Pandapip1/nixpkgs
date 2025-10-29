{ lib }:
let
  inherit (lib) optionalAttrs;
in
rec {
  mkLicense =
    licenseId:
    {
      shortName ? null,
      fullName ? null,
      spdxId ? null,
      url ? null,
      deprecated ? false,
      terms,
    }@attrs:
    {
      inherit
        licenseId
        deprecated
        redistributable
        terms
        ;
      free =
        lib.all (condition: condition.osdCompliant) (terms.use or [ { osdCompliant = false; } ])
        && lib.all (condition: condition.osdCompliant) (terms.binaryRedistribution or [ { osdCompliant = false; } ])
        && lib.all (condition: condition.osdCompliant) (terms.sourceRedistribution or [ { osdCompliant = false; } ])
        && lib.all (condition: condition.osdCompliant) (terms.sourceAvailability or [ { osdCompliant = false; } ])
        && lib.all (condition: condition.osdCompliant) (terms.modification or [ { osdCompliant = false; } ])
        && lib.all (condition: condition.osdCompliant) (terms.licenseDistribution or [ { osdCompliant = false; } ]);
    }
    // optionalAttrs (attrs ? spdxId) {
      inherit spdxId;
      url = "https://spdx.org/licenses/${spdxId}.html";
    }
    // optionalAttrs (attrs ? url) {
      inherit url;
    }
    // optionalAttrs (attrs ? fullName) {
      inherit fullName;
    }
    // optionalAttrs (attrs ? shortName) {
      inherit shortName;
    };

  mkCondition =
    conditionId:
    {
      name,
      description ? null,
      deprecated ? false,
      osdCompliant ? false,
      appliesTo ? null,
    }@attrs:
    {
      inherit
        conditionId
        name
        deprecated
        ;
    }
    // optionalAttrs (attrs ? description) {
      inherit description;
    }
    // optionalAttrs (attrs ? appliesTo) {
      inherit appliesTo;
    };

  mkFreedom =
    freedomId:
    {
      name,
      description ? null,
      deprecated ? false,
    }@attrs:
    {
      inherit
        freedomId
        name
        deprecated
        ;
    }
    // optionalAttrs (attrs ? description) {
      inherit description;
    };

  conditions = lib.mapAttrs mkCondition {
    attribution = {
      name = "Attribution";
      osdCompliant = true;
      appliesTo = with freedoms; [
        modification
        sourceRedistribution
        binaryRedistribution
        modification
      ];
    };
    copyOfLicense = {
      name = "Copy of License";
      osdCompliant = true;
      appliesTo = with freedoms; [
        sourceRedistribution
        binaryRedistribution
        modification
      ];
    };
    copyrightNotice = {
      name = "Copyright Notice Required";
      osdCompliant = true;
      appliesTo = with freedoms; [
        sourceRedistribution
        binaryRedistribution
        modification
      ];
    };
    copyleft = {
      name = "Copyleft";
      osdCompliant = true;
      appliesTo = with freedoms; [
        sourceRedistribution
        binaryRedistribution
      ];
    };
    reasonablePaidSource = {
      name = "Paid source code (OSD-compliant)";
      description = "A reasonable reproduction cost must be paid in order to gain access to the source code";
      osdCompliant = true;
      appliesTo = with freedoms; [
        sourceAvailability
      ];
    };
    unfreePaidSource = {
      name = "Paid source code";
      description = "A fee must be paid in order to gain access to the source code beyond what is alloed by the OSD";
      appliesTo = with freedoms; [
        sourceAvailability
      ];
    };
    noAggregation = {
      name = "No Aggregation";
      description = "The license does not permit bundled distribution";
      appliesTo = with freedoms; [
        binaryRedistribution
        sourceRedistribution
      ];
    };
    nonCommercial = {
      name = "No Commercial Use";
      description = "The license does not permit commercial use";
    };
    nonLawEnforcement = {
      name = "No Law Enforcement Use";
      description = "The license does not permit law enforcement use";
    };
    nonMilitary = {
      name = "No Military Use";
      description = "The license does not permit military use";
    };
    patchOnly = {
      name = "Only patches allowed";
      description = "The license restricts modified source code from being distributed, but allows patch files";
      osdCompliant = true;
      appliesTo = with freedoms; [
        sourceRedistribution
      ];
    };
    differentName = {
      name = "Distributed derivative works must carry a different name";
      osdCompliant = true;
      appliesTo = with freedoms; [
        binaryRedistribution
        sourceRedistribution
      ];
    };
    differentVersion = {
      name = "Distributed derivative works must carry a different version";
      osdCompliant = true;
      appliesTo = with freedoms; [
        binaryRedistribution
        sourceRedistribution
      ];
    };
    productSpecific = {
      name = "Product specific";
      description = "The right depends on the work being part of a particular software distribution";
    };
    restrictsOtherSoftware = {
      name = "Restricts other software";
    };
    nonTechnologyNeutral = {
      name = "Non Technology-Neutral";
    };
    warrantyDisclaimer = {
      name = "Warranty Disclaimer";
      description = "The work does not carry any warranty, express or implied";
      osdCompliant = true;
      appliesTo = with freedoms; [
        use
      ];
    };
    liabilityWaiver = {
      name = "Liability Waiver";
      description = "Agreement to the license waives liability for the copyright holders and/or authors";
      osdCompliant = true;
    };
    otherDiscriminationPersons = {
      name = "Discriminates against one or more persons";
    };
    otherDiscriminationGroups = {
      name = "Discriminates against one or more groups";
    };
    otherDiscriminationFieldEndeavor = {
      name = "Discriminates against one or more fields of endeavor";
    };
  };

  freedoms = lib.mapAttrs mkFreedom {
    use = {
      name = "Use of the work";
    };
    binaryRedistribution = {
      name = "Redistribution of binaries under the same license";
    };
    sourceRedistribution = {
      name = "Redistribution of source code under the same license";
    };
    sourceAvailability = {
      name = "Availability of source code";
    };
    modification = {
      name = "Modifications to the work and creation of derivative works";
    };
    licenseDistribution = {
      name = "Terms of the license are preserved when the work is distributed";
    };
  };
}
