local function createButton(name, position, parent)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = UDim2.new(0, 260, 0, 50)
    button.Position = position
    button.BackgroundTransparency = 0.2
    button.BorderSizePixel = 0
    button.Text = ""          -- leave empty
    button.AutoButtonColor = false
    button.Parent = parent

    local UICornerBtn = Instance.new("UICorner")
    UICornerBtn.CornerRadius = UDim.new(0, 12)
    UICornerBtn.Parent = button

    -- sky-blue background gradient
    local skyGradient = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(135, 206, 235)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(70, 130, 180)),
    }
    local buttonBGGradient = Instance.new("UIGradient")
    buttonBGGradient.Color = skyGradient
    buttonBGGradient.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.4),
        NumberSequenceKeypoint.new(1, 0.4),
    }
    buttonBGGradient.Parent = button

    -- rainbow text label
    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, 0, 1, 0)
    text.BackgroundTransparency = 1
    text.Text = name
    text.TextColor3 = Color3.new(1, 1, 1)
    text.Font = Enum.Font.GothamSemibold
    text.TextSize = 22
    text.Parent = button

    local rainbow = ColorSequence.new{
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(255, 0, 0)),
        ColorSequenceKeypoint.new(0.17,Color3.fromRGB(255, 165, 0)),
        ColorSequenceKeypoint.new(0.33,Color3.fromRGB(255, 255, 0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 0)),
        ColorSequenceKeypoint.new(0.67,Color3.fromRGB(0, 255, 255)),
        ColorSequenceKeypoint.new(0.83,Color3.fromRGB(0, 0, 255)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(128, 0, 128)),
    }
    local textGradient = Instance.new("UIGradient")
    textGradient.Color = rainbow
    textGradient.Parent = text

    -- slow infinite rainbow scroll
    game:GetService("TweenService"):Create(
        textGradient,
        TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
        {Offset = Vector2.new(1, 0)}
    ):Play()

    button.MouseEnter:Connect(function()
        buttonBGGradient.Transparency = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 0.2),
            NumberSequenceKeypoint.new(1, 0.2),
        }
    end)

    button.MouseLeave:Connect(function()
        buttonBGGradient.Transparency = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 0.4),
            NumberSequenceKeypoint.new(1, 0.4),
        }
    end)

    return button
end
