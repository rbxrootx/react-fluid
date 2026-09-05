local React = require("../../React")
local useReveal = require("../../Fluid/useReveal")

-- Top-hinged, clipped unfold for tabs/cards. The content retains its full
-- height while the visible aperture opens. One Frame mask, no CanvasGroup
-- render target or copy of the subtree per slat. Pixel height is explicit so
-- parent layouts and scale-sized children cannot feed back into each other.
return function(props)
	assert(type(props.height) == "number" and props.height > 0, "Reveal needs a positive pixel height")
	local progress = useReveal(props.open, props)
	local zIndex = props.ZIndex or 1
	local width = props.width or UDim.new(1, 0)
	return React.createElement("Frame", {
		Name = props.Name or "FluidReveal",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		LayoutOrder = props.LayoutOrder,
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		Size = progress:map(function(value)
			return UDim2.new(width.Scale, width.Offset, 0, props.height * math.clamp(value, 0, 1))
		end),
		ZIndex = zIndex,
	}, {
		Content = React.createElement("Frame", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, props.height),
			ZIndex = zIndex + 1,
		}, props.children),
	})
end
