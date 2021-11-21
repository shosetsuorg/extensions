-- {"ver":"1.0.0","author":"Dunbock",dep":["htmlEntities"]}

local htmlEntities = Require("htmlEntities")

--- Removes the duplicate link entries from a list of novels.
---@param novelList {Novel} A list of novels.
---@param hash [boolean] If true, then the key (the link) has already been shown.
---@return {Novel} The list of novels with removed duplicates.
local function removeDuplicateNovels(novelList, hash)
	local res = {}
	if hash == nil then
		hash = {}
	end

	for _, novel in ipairs(novelList) do
		if (not hash[novel:getLink()]) then
			res[#res+1] = novel -- you could print here instead of saving to result table if you wanted
			hash[novel:getLink()] = true
		end
	end
	--[=====[
	print("Source length: " .. #novelList)
	print("Length: " .. #res)
	for i, v in ipairs(res) do
		print( i .. " " .. v:getTitle() .. " " .. v:getLink() .. " " .. v:getImageURL() )
	end
	--]=====]

	return res, hash
end

--- Attempts to convert HTML to text.
--- @param html Element Is either a HTML Element or a string containting HTML tags.
--- @param convertLinebreaks boolean If true, then </p> and <br> get converted into linebreaks.
--- @param useElementContent boolean If true, then the Element content will be converted. This implicitly adds line breaks between all HTML tags and content.
--- @return string The inner HTML cleaned of HTML tags keeping the same line breaks.
local function convertHTMLToText(html, convertLinebreaks, useElementContent)
	if  html == nil then
		return
	end

	-- Handle the Element content of the HTML Element if requested.
	if useElementContent then
		html = html:html()
	end

	-- Decode HTML entities
	html = htmlEntities.decode(html)

	-- Convert Linebreaks if requested, otherwise remove tags.
	if convertLinebreaks then
		html = html:gsub("</p>", "\n")
		html = html:gsub("<br>", "\n")
	else
		html = html:gsub("</p>", "")
		html = html:gsub("<br>", "")
	end

	-- Remove or replace the rest of the HTML tags.
	html = html:gsub("<p[^>]*>", "")

	html = html:gsub("<div[^>]*>", "")
	html = html:gsub("</div>", "")

	html = html:gsub("<span[^>]*>", "")
	html = html:gsub("</span>", "")

	html = html:gsub("<strong[^>]*>", "")
	html = html:gsub("</strong>", "")

	html = html:gsub("<em[^>]*>", "")
	html = html:gsub("</em>", "")

	html = html:gsub("<blockquote[^>]*>", "")
	html = html:gsub("</blockquote>", "")

	html = html:gsub("<a[^>]*>", "")
	html = html:gsub("</a>", "")

	html = html:gsub("<meta[^>]*>", "")

	html = html:gsub("<hr>", "\n-------------------\n")

	return html
end

return {
	removeDuplicateNovels = removeDuplicateNovels,
	convertHTMLToText = convertHTMLToText,
}
