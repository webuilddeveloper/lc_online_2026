# WebRTC Hub — Backend Spec

SignalR hub แยกจาก `chatHub` สำหรับ video call signaling เท่านั้น  
**ไม่บันทึก DB, ไม่เขียน chat history**

## Endpoint

```
GET/WS  {API_BASE}/webrtcHub
```

ตัวอย่าง: `https://line-ddpm.we-builds.com/lc-lawyer-api/webrtcHub`

ลงทะเบียนใน `Program.cs` / `Startup.cs`:

```csharp
app.MapHub<WebRtcHub>("/webrtcHub");
```

## Hub Contract

### Client → Server (invoke)

| Method | Args | คำอธิบาย |
|--------|------|----------|
| `JoinRoom` | `string roomCode`, `string userId`, `string caseCode` | เข้า group ตาม `roomCode` |
| `LeaveRoom` | `string roomCode`, `string userId` | ออกจาก group |
| `SendSignal` | `string roomCode`, `string fromUserId`, `object signal` | relay SDP/ICE/hangup |
| `StartCall` | `string roomCode`, `string fromUserId`, `string caseCode`, `string peerName` | แจ้งสายเข้า (ไม่ persist) |

### Server → Client (events)

| Event | Payload | คำอธิบาย |
|-------|---------|----------|
| `ReceiveSignal` | `{ from, action, sdp?, candidate? }` | signaling จาก peer |
| `IncomingCall` | `{ roomCode, fromUserId, caseCode, peerName }` | มีคนโทรเข้า |
| `PeerJoined` | `{ userId, caseCode }` | optional — peer เข้าห้อง |
| `PeerLeft` | `{ userId }` | optional — peer ออกห้อง |

### Signal `action` values (Flutter)

| action | ฟิลด์เพิ่ม |
|--------|-----------|
| `ready` | — |
| `offer` | `sdp` |
| `answer` | `sdp` |
| `ice` | `candidate` (object) |
| `hangup` | — |

## Reference Implementation (.NET)

```csharp
using Microsoft.AspNetCore.SignalR;

public class WebRtcHub : Hub
{
    public async Task JoinRoom(string roomCode, string userId, string caseCode)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, roomCode);
        await Clients.OthersInGroup(roomCode).SendAsync("PeerJoined", new
        {
            userId,
            caseCode,
        });
    }

    public async Task LeaveRoom(string roomCode, string userId)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, roomCode);
        await Clients.OthersInGroup(roomCode).SendAsync("PeerLeft", new { userId });
    }

    public async Task SendSignal(string roomCode, string fromUserId, object signal)
    {
        await Clients.OthersInGroup(roomCode).SendAsync("ReceiveSignal", new
        {
            from = fromUserId,
            // merge signal properties (action, sdp, candidate)
        });
    }

    public async Task StartCall(
        string roomCode,
        string fromUserId,
        string caseCode,
        string peerName)
    {
        await Clients.OthersInGroup(roomCode).SendAsync("IncomingCall", new
        {
            roomCode,
            fromUserId,
            caseCode,
            peerName,
        });
    }
}
```

`SendSignal` ควร merge `signal` object เข้า payload ก่อนส่ง (flat: `from`, `action`, `sdp`, `candidate`)

## ความแตกต่างจาก chatHub

| | chatHub | webrtcHub |
|---|---------|-----------|
| บันทึก DB | ใช่ | **ไม่** |
| ประวัติแชท | ใช่ | **ไม่** |
| ใช้กับ | ข้อความ, ไฟล์ | WebRTC signaling เท่านั้น |
| LoadHistory | มี | **ไม่มี** |

## Auth (แนะนำ)

- ใช้ JWT / cookie เดียวกับ API อื่น
- Validate `userId` ตรงกับ claim ก่อน `JoinRoom` / `SendSignal`
- Optional: ตรวจว่า user มีสิทธิ์ใน `caseCode` ก่อนเข้าห้อง

## Deploy checklist

- [ ] สร้าง `WebRtcHub.cs`
- [ ] Map `/webrtcHub` + CORS เดียวกับ chatHub
- [ ] ทดสอบ 2 client join room เดียวกัน → `ReceiveSignal` relay ได้
- [ ] ยืนยันว่า signaling **ไม่** ไปที่ chat DB / chat history

## Flutter files (ฝั่ง app)

- `lib/services/webrtc_hub_service.dart` — SignalR client
- `lib/services/webrtc_signaling_service.dart` — offer/answer/ice
- `lib/services/webrtc_call_listener_service.dart` — incoming call ในหน้าแชท
- `lib/shared/api_provider.dart` — `webrtcHubUrl`
