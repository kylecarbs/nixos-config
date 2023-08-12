// This fetches the latest version of each extension and updates the
// vscode-extensions.json file with the new version and sha256 hash.
//
// This makes it much easier to manage VS Code extensions with Nix.
import { createHash } from "https://deno.land/std@0.108.0/hash/mod.ts";
import * as semver from "https://deno.land/std@0.198.0/semver/mod.ts";

interface Extension {
  readonly publisher: string;
  readonly name: string;

  version?: string;
  sha256?: string;
}

const fetchExtension = async (publisher: string, name: string) => {
  const requestUrl = `https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery`;
  const postData = JSON.stringify({
    filters: [
      {
        // Filter type 7 is by ID.
        criteria: [{ filterType: 7, value: `${publisher}.${name}` }],
      },
    ],
    // Hardcoded and discovered from browsing the VS Code marketplace on the web.
    // This ensures versions are returned!
    flags: 2151,
  });
  const result = await fetch(requestUrl, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Accept-Encoding": "gzip",
      Accept: "application/json;api-version=3.0-preview",
    },
    body: postData,
  });
  const response: {
    results?: [
      {
        extensions: [
          {
            versions: [
              {
                version: string;
                files: [
                  {
                    assetType: string;
                    source: string;
                  }
                ];
              }
            ];
          }
        ];
      }
    ];
  } = await result.json();
  if (
    !response.results ||
    !response.results.length ||
    !response.results[0].extensions.length ||
    !response.results[0].extensions[0].versions.length
  ) {
    throw new Error(
      "no results for " +
        publisher +
        "." +
        name +
        ": " +
        JSON.stringify(response)
    );
  }
  const version = response.results[0].extensions[0].versions[0];
  const vsix = version.files.filter(
    (v) => v.assetType === "Microsoft.VisualStudio.Services.VSIXPackage"
  );
  if (!vsix.length) {
    throw new Error("no vsix found");
  }

  return {
    version: response.results[0].extensions[0].versions[0].version,
    downloadURL: vsix[0].source,
  };
};

const downloadAndHash = async (url: string) => {
  const res = await fetch(url);
  const hash = createHash("sha256");
  hash.update(await res.arrayBuffer());
  const hashInBase64 = btoa(
    String.fromCharCode.apply(null, Array.from(new Uint8Array(hash.digest())))
  );
  return `sha256-${hashInBase64}`;
};

const text = await Deno.readTextFile("./hosts/vscode-extensions.json");
const extensions: ReadonlyArray<Extension> = JSON.parse(text);

for (const extension of extensions) {
  const resp = await fetchExtension(extension.publisher, extension.name);
  const id = extension.publisher + "." + extension.name;
  if (extension.version) {
    try {
      const current = semver.parse(extension.version);
      const latest = semver.parse(resp.version);
      if (semver.compare(current, latest) >= 0) {
        continue;
      }
    } catch {
      // Continue...
    }
  }
  extension.version = resp.version;
  extension.sha256 = await downloadAndHash(resp.downloadURL);
  console.log("Updated", id, "to", resp.version + "!");
}

Deno.writeTextFile(
  "./hosts/vscode-extensions.json",
  JSON.stringify(extensions, undefined, "  ")
);
