/**
 * 设备 token 登记：userId → FCM token 集合。
 *
 * 客户端拿到 FCM token 后登记一次，服务端推送时按 userId 找 token。
 *
 * ponytail: 内存表，服务重启就丢 —— 客户端每次启动都会重新登记，丢一下不影响。
 *         要跨重启就落盘（token 一行一条 JSON）。
 */
export class DeviceRegistry {
  private readonly byUser = new Map<string, Set<string>>();

  /** 登记一个 token（同一个用户重复登记同一个 token 不重复存）。 */
  register(userId: string, token: string): void {
    const set = this.byUser.get(userId) ?? new Set<string>();
    set.add(token);
    this.byUser.set(userId, set);
  }

  /** 某个用户的所有 token。 */
  tokensOf(userId: string): string[] {
    return [...(this.byUser.get(userId) ?? [])];
  }
}
