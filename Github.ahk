#Include <JSON>
Class Github {
	static getLatestRelease(user, repo) {
		whr := ComObject("WinHttp.WinHttpRequest.5.1")
		whr.Open("GET", "https://api.github.com/repos/" user "/" repo "/releases/latest", false)
		whr.send()
		return JSON.parse(whr.responseText)
	}
	static getLatestReleaseVersion(user, repo) {
		return Github.getLatestRelease(user, repo)["tag_name"]
	}
	static downloadLatest(user, repo, path, assetNum:=1) {
		Download (n:=this.getLatestRelease(user, repo)["assets"][assetNum])["browser_download_url"], path "\" n["name"]
	}
	static getLatestZip(user, repo, path) {
		Download "https://github.com/" user "/" repo "/archive/" Github.getLatestReleaseVersion(user, repo) ".zip", path
	}
	static getLatestTar(user, repo, path) {
		Download "https://github.com/" user "/" repo "/archive/" Github.getLatestReleaseVersion(user, repo) ".tar.gz", path "\" repo ".tar.gz"
	}
}
