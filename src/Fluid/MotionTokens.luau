--!strict
-- Defaults belong here; applications can pass their own design-system tokens.
return table.freeze({
	Spring = table.freeze({
		gentle = table.freeze({ speed = 12, damper = 1 }),
		responsive = table.freeze({ speed = 28, damper = 0.86 }),
		smooth = table.freeze({ speed = 22, damper = 1 }),
		bouncy = table.freeze({ speed = 20, damper = 0.62 }),
		soft = table.freeze({ speed = 14, damper = 0.8 }),
		stiff = table.freeze({ speed = 36, damper = 0.95 }),
		slow = table.freeze({ speed = 8, damper = 1 }),
	}),
	Duration = table.freeze({ reveal = 0.42, stagger = 0.035, collect = 0.52 }),
	Precision = table.freeze({ position = 0.0001, velocity = 0.001 }),
})
