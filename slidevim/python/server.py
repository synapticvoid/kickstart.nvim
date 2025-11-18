#!/usr/bin/env python3
"""Slidevim WebSocket server - runs as standalone process
# /// script
# dependencies = ["websockets>=12.0"]
# ///
"""

import asyncio
import json
import sys
from typing import Set
import websockets
from websockets.server import serve, WebSocketServerProtocol

WS_PORT = 8765
NVIM_PORT = 8766
ws_clients: Set[WebSocketServerProtocol] = set()
nvim_clients = set()
loop = None
ws_server = None
nvim_server = None


async def handle_websocket(websocket: WebSocketServerProtocol):
    """Handle a WebSocket client (Chrome) connection"""
    ws_clients.add(websocket)
    print(f"[Slidevim] WebSocket client connected, total: {len(ws_clients)}", flush=True)
    
    try:
        async for message in websocket:
            print(f"[Slidevim] WS received: {message}", flush=True)
            # Broadcast to Neovim clients (newline-delimited JSON)
            if nvim_clients:
                for writer in nvim_clients:
                    writer.write(message.encode() + b'\n')
                    await writer.drain()
    except websockets.exceptions.ConnectionClosed:
        pass
    finally:
        ws_clients.discard(websocket)
        print(f"[Slidevim] WebSocket client disconnected, total: {len(ws_clients)}", flush=True)


async def handle_nvim_client(reader, writer):
    """Handle a Neovim TCP client connection"""
    nvim_clients.add(writer)
    addr = writer.get_extra_info('peername')
    print(f"[Slidevim] Neovim client connected from {addr}", flush=True)
    
    try:
        while True:
            data = await reader.readline()
            if not data:
                break
            
            message = data.decode().strip()
            if message:
                print(f"[Slidevim] Nvim received: {message}", flush=True)
                # Broadcast to WebSocket clients
                if ws_clients:
                    await asyncio.gather(
                        *[client.send(message) for client in ws_clients],
                        return_exceptions=True
                    )
    except Exception as e:
        print(f"[Slidevim] Nvim client error: {e}", flush=True)
    finally:
        nvim_clients.discard(writer)
        writer.close()
        await writer.wait_closed()
        print(f"[Slidevim] Neovim client disconnected", flush=True)


async def start_servers():
    """Start both WebSocket and TCP servers"""
    global ws_server, nvim_server
    
    # Start WebSocket server for Chrome
    ws_server = await serve(handle_websocket, "127.0.0.1", WS_PORT)
    print(f"[Slidevim] WebSocket server running on ws://127.0.0.1:{WS_PORT}", flush=True)
    
    # Start TCP server for Neovim
    nvim_server = await asyncio.start_server(handle_nvim_client, "127.0.0.1", NVIM_PORT)
    print(f"[Slidevim] Neovim TCP server running on 127.0.0.1:{NVIM_PORT}", flush=True)
    
    await asyncio.Future()  # Run forever


def run_server():
    """Entry point to run the server"""
    global loop
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    try:
        loop.run_until_complete(start_servers())
    except KeyboardInterrupt:
        pass
    finally:
        if ws_server:
            ws_server.close()
        if nvim_server:
            nvim_server.close()
        loop.close()


if __name__ == "__main__":
    run_server()
