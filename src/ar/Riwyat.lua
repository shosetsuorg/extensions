-- {"id":3303,"ver":"1.0.0","libVer":"1.0.0","author":"Ali Mohamed","dep":["Madara>=2.1.0"]}

local baseURL = "https://riwyat.com"

local function expandURL(url)
	return baseURL .. "/novel/" .. url
end

return Require("Madara")(baseURL, {
	id = 3303,
	name = "Riwyat - فضاءالروايات",
	imageURL = "https://riwyat.com/wp-content/uploads/2017/10/gjggjjh.png",
	genres = {
		"رومانسية",
		"مكتملة",
		"فنون قتالية",
		"دراما",
		"أكشن",
		"للكبار",
		"مغامرة",
		"كوميك",
		"أيتشي",
		"فانتازيا",
		"حريم",
		"تاريخي",
		"رعب",
		"جوسي",
		"حياة يومية",
		"بالغ",
		"مانجا",
		"غموض",
		"مانها",
		"وان شوت",
		"مانهوا",
		"نفسي",
		"خيال علمي",
		"سنين",
		"شريحة حياة",
		"رياضي",
		"مأساة",
		"قوى خارقة",
		"واب تون"
	},
	expandURL = expandURL,
	chaptersScriptLoaded = true,
    novelPageTitleSel = "h1",
	getPassage = function (url)
        local res = Document(Request(GET(expandURL(url))):body():string():gsub("html","div"):gsub("&nbsp;", ""))
		local htmlElement = res:selectFirst("div.text-center")
		htmlElement:select("div span font"):remove()
		htmlElement:select("div > a"):remove()
		htmlElement:select("div.ad > h3"):remove()
		htmlElement:select("div.ad > h4"):remove()

		return pageOfElem(htmlElement)
 
	end

}) 