import { cached, tracked } from "@glimmer/tracking";
import { getWeekNumber } from "./helpers";
import { ONE_MINUTE_MS, ONE_WEEK_MS } from "./consts";

class Clock {
  /**
   * Date instance for the current time,
   * accurate to within one minute.
   */
  @tracked now: Date;
  @tracked firstDayOfWeek: 'monday' | 'sunday' = 'monday';

  constructor() {
    this.now = new Date();

    setInterval(() => {
      this.now = new Date();
    }, ONE_MINUTE_MS);
  }

  /**
   * Get today's date, year, and week number
   */
  @cached
  get today() {
    const today = new Date();
    const year = today.getFullYear();
    const day = this.firstDayOfWeek;
    const weekNo = getWeekNumber(today, day);

    return {
      today,
      year,
      weekNo,
      day,
    }
  }

  @cached
  get nextWeek() {
    const today = new Date();
    const nextWeekDate = new Date(today.getTime() + ONE_WEEK_MS);

    const year = nextWeekDate.getFullYear();
    const day = this.firstDayOfWeek;
    const weekNo = getWeekNumber(nextWeekDate, day);

    return {
      today: nextWeekDate,
      year,
      weekNo,
      day,
    }
  }

  @cached
  get daysRemainingInWeek(): number {
    const dayOfWeek = this.now.getDay(); // 0=Sun, 1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri, 6=Sat
    const firstDayNum = this.firstDayOfWeek === 'monday' ? 1 : 0;

    if (dayOfWeek === firstDayNum) {
      return 7;
    } else if (dayOfWeek > firstDayNum) {
      return 7 - dayOfWeek + firstDayNum;
    } else {
      return firstDayNum - dayOfWeek;
    }
  }
}

const clock = new Clock();

export { clock };
