-- represents the background for the entire combo graph

return Def.Quad {
	Name = "Backing",
	InitCommand = function(self)
		self:diffuse(color("#111111EE"))
	end
}
