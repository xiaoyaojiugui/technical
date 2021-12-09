import asyncio
import pyppeteer
import tkinter
from pyppeteer import launch

pyppeteer.DEBUG = True  # print suppressed errors as error log

'''使用tkinter获取屏幕大小'''
def screen_size():
    tk = tkinter.Tk()
    width = tk.winfo_screenwidth()
    height = tk.winfo_screenheight()
    tk.quit()
    return width, height

async def get_titile_name(elements):
    print(elements)
    for item in elements:
        print(len(elements))
        print(type(item))
        print(dir(item))
        textConent = await item.getProperty('textContent')
        print(dir(textConent))
        # 获取文本
        title_str = (await (await item.getProperty('textContent')).jsonValue()).strip()
        # 获取链接
        title_link = await (await item.getProperty('href')).jsonValue()


async def main():
    # headless参数设为False，则变成有头模式
    browser = await launch({'headless': True})

    page = await browser.newPage()

    # 设置页面视图大小
    width, height = screen_size()
    await page.setViewport({
        'width': width,
        'height': height
    })

    url = "https://mp.weixin.qq.com/s/qZW3lxPVcGOPxmxHpyTh4A"
    res = await page.goto(url)

    get_titile_name(await page.xpath('//*[@id="activity-name"]'))

    # 滚动到页面底部
    await page.evaluate('''async () => {
        await new Promise((resolve, reject) => {
            var totalHeight = 0;
            var distance = 100;
            var scrollHeight = document.body.scrollHeight - 1100;
            var timer = setInterval(() => {
                // scrollBy() 会使元素每隔一秒从当前的滚动条位置向下滚动10px，这是一个设置相对滚动条位置的方法。
                window.scrollBy(0, distance);
                totalHeight += distance;
             if (totalHeight >= scrollHeight){
                    clearInterval(timer);
                    resolve();
                }
            }, 100);
        });
    }''')

    await page.pdf({
        "path": "~/data/laozhao/2021-09-16-黑天鹅突袭，大牛股惨遭股债双杀.pdf",
        "format": 'A4'})

    await browser.close()

if __name__ == '__main__':
    asyncio.get_event_loop().run_until_complete(main())
