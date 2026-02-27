import math
from PIL import Image, ImageDraw

def generate_pirate_walk():
    width, height = 24, 38
    frames = 8
    skin = (245, 189, 142, 255)
    shirt = (230, 230, 230, 255)
    coat = (70, 70, 150, 255)
    pants = (120, 100, 80, 255)
    boots = (40, 30, 30, 255)
    hair = (255, 220, 100, 255)
    
    for f in range(frames):
        img = Image.new("RGBA", (width, height), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        bob = -1 if f in [1, 5] else 0
        cx, cy = 12, 10 + bob
        # Hair
        draw.rectangle([cx-3, cy-4, cx+4, cy], fill=hair)
        # Face
        draw.rectangle([cx-2, cy-2, cx+3, cy+3], fill=skin)
        # Shirt/Coat
        draw.rectangle([cx-4, cy+4, cx+3, cy+14], fill=coat)
        draw.rectangle([cx-1, cy+4, cx+2, cy+14], fill=shirt)
        
        # Arms
        arm_swing = math.sin((f / frames) * math.pi * 2) * 4
        # right arm (back)
        draw.line([cx+1, cy+5, cx+2+arm_swing, cy+12], fill=coat, width=3)
        draw.rectangle([cx+1+arm_swing, cy+11, cx+3+arm_swing, cy+13], fill=skin)
        # left arm (front)
        draw.line([cx-2, cy+5, cx-3-arm_swing, cy+12], fill=coat, width=3)
        draw.rectangle([cx-4-arm_swing, cy+11, cx-2-arm_swing, cy+13], fill=skin)
        
        # Legs
        leg_swing = math.sin((f / frames) * math.pi * 2) * 5
        # right leg (back)
        draw.line([cx, cy+14, cx + leg_swing, cy+22], fill=pants, width=3)
        draw.rectangle([cx+leg_swing-1, cy+22, cx+leg_swing+2, cy+24], fill=boots)
        
        # left leg (front)
        draw.line([cx-1, cy+14, cx - 1 - leg_swing, cy+22], fill=pants, width=3)
        draw.rectangle([cx-1-leg_swing-1, cy+22, cx-1-leg_swing+2, cy+24], fill=boots)
        
        filePath = f"/Users/peppe/Desktop/PixelParallaxScreensaver/PixelParallax/Assets/hero_walk_{f+1}.png"
        img.save(filePath)
        print(filePath)

generate_pirate_walk()