import asyncio
import pyppeteer
import tkinter


class Runner:
    def __init__(self):
        self.loop = asyncio.new_event_loop()  # *new*_event_loop

    def __enter__(self):
        return self

    def __exit__(self, *args):
        self.loop.close()

    def do_work(self):
        # Make sure all futures are created
        # with relevant event loop been set as current
        asyncio.set_event_loop(self.loop)

        # ...
        return self.loop.run_until_complete(asyncio.gather('httyps://mp.weixin.qq.com/s/gsy64ZWk91QA6m0oVoHZig'))


if __name__ == '__main__':
    gen = Runner()
    gen.do_work()
    asyncio.get_event_loop().run_until_complete(main())