//
//  CTLineUtils.m
//  DTCoreText
//
//  Created by Oleksandr Deundiak on 7/15/15.
//  Copyright 2015. All rights reserved.
//

#import "CTLineUtils.h"

/// 判断两行是否相等
/// @param line1 行一
/// @param line2 行二
BOOL areLinesEqual(CTLineRef line1, CTLineRef line2)
{
    // 如果任一行为空，则不相等
	if(line1 == nil || line2 == nil) {
		return NO;
	}
	
    // 获取行的字形集合体数组(可以简单理解为这一行中有几种格式的文字)
    CFArrayRef glyphRuns1 = CTLineGetGlyphRuns(line1);
    CFArrayRef glyphRuns2 = CTLineGetGlyphRuns(line2);
    CFIndex runCount1 = CFArrayGetCount(glyphRuns1), runCount2 = CFArrayGetCount(glyphRuns2);
    
    // 如果行字形集合体数不相等，则不相等
    if (runCount1 != runCount2)
        return NO;
    
    for (CFIndex i = 0; i < runCount1; i++)
    {
        // 获取字形集合体数组中，具有相同格式的那一段
        CTRunRef run1 = CFArrayGetValueAtIndex(glyphRuns1, i);
        CTRunRef run2 = CFArrayGetValueAtIndex(glyphRuns2, i);
        
        // 如果具有相同格式的字符数不相等，那么这一行也不相等
        CFIndex countInRun1 = CTRunGetGlyphCount(run1), countInRun2 = CTRunGetGlyphCount(run2);
        if (countInRun1 != countInRun2)
            return NO;
        
        // 取出两行中具有相同格式的字符，并将它们分别放在 constGlyphs1 和 constGlyphs2 中
        const CGGlyph* constGlyphs1 = CTRunGetGlyphsPtr(run1);
		CGGlyph* glyphs1 = NULL;
        if (constGlyphs1 == NULL)
        {
            glyphs1 = (CGGlyph*)malloc(countInRun1*sizeof(CGGlyph));
            CTRunGetGlyphs(run1, CFRangeMake(0, countInRun1), glyphs1);
			constGlyphs1 = glyphs1;
        }
        
        const CGGlyph* constGlyphs2 = CTRunGetGlyphsPtr(run2);
		CGGlyph* glyphs2 = NULL;
        if (constGlyphs2 == NULL)
        {
            glyphs2 = (CGGlyph*)malloc(countInRun2*sizeof(CGGlyph));
            CTRunGetGlyphs(run2, CFRangeMake(0, countInRun2), glyphs2);
			constGlyphs2 = glyphs2;
        }
        
        // 比对具体每一个字符，如果有不相同的字符，则这两行也互不相等
        BOOL result = YES;
        for (CFIndex j = 0; j < countInRun1; j++)
        {
            if (constGlyphs1[j] != constGlyphs2[j])
            {
                result = NO;
                break;
            }
        }
        
        if (glyphs1 != NULL)
            free(glyphs1);
        
        if (glyphs2 != NULL)
            free(glyphs2);
        
        if (!result)
            return NO;
    }
    
    return YES;
}


/// 指定需要截断的行，以及truncationToken，返回截断的 index
/// @param line 需要被截断的行
/// @param trunc 以什么来截断
CFIndex getTruncationIndex(CTLineRef line, CTLineRef trunc)
{
    // 如果行为空，则直接返回
	if (line == nil || trunc == nil) return 0;
	
    // 获取该行的字形集合体数（有几种格式）
	CFIndex truncCount = CFArrayGetCount(CTLineGetGlyphRuns(trunc));
    CFArrayRef lineRuns = CTLineGetGlyphRuns(line);
    CFIndex lineRunsCount = CFArrayGetCount(lineRuns);
    
        // 拿到 index，就是整一行的字形集合数 - 截断内容的字体集合数 - 1
        // 假设我们的 line 是 [字形集合1][字形集合2][字形集合3]
        // truncation 是 [字形集合4]
        // 那我们就需要在 3 - 1 - 1 处，也就是[字形集合2]后面进行截断
        // 假设我们的 line 是 [字形集合1][字形集合2][字形集合3]
        // truncation 是 [字形集合4][字形集合 5]
        // 那我们就需要在 3 - 2 - 1 处，也就是[字形集合1]后面进行截断
    
        // TODO DILLION: 怎么感觉有点不对劲
		CFIndex index = lineRunsCount - truncCount - 1;

		// If the index is negative, CFArrayGetValueAtIndex will crash on iOS 10 beta.
		// We will just return 0 because on iOS 9, CFArrayGetValueAtIndex would have
		// returned nil anyways and the return truncation index would be 0.
		// Apple might have enabled an assert that only appears in the iOS 10 beta
		// release, but we will just avoid passing invalid arguments just to be safe.
		if (index < 0)
		{
			return 0;
		}
		else
		{
            // 拿到需要截断的 index 了，获取在该 index 上的 CTRun
			CTRunRef lineLastRun = CFArrayGetValueAtIndex(lineRuns, index);
            // 拿到该 CTRun 的range
			CFRange lastRunRange = CTRunGetStringRange(lineLastRun);
            // 让 range 的 location 等于该 range 的长度，也就是说，需要在 range 后截断
			return lastRunRange.location = lastRunRange.length;
		}
}
