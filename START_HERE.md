# Start here

1. Create a **new public repository**. Do not make the old private bot repository public.
2. Extract the ZIP and upload all contents inside `snapchat-headline-public-safe`.
3. Confirm `.github/workflows/snapchat-headline-editor.yml` exists.
4. In **Settings → Secrets and variables → Actions → Secrets**, add:
   - `SNAP_CLIENT_ID`
   - `SNAP_CLIENT_SECRET`
   - `SNAP_REFRESH_TOKEN`
   - `OPENAI_API_KEY`
   - `SNAP_AD_ACCOUNT_ID`
   - `PRODUCT_CONTEXT`
   - `STATE_ENCRYPTION_KEY`
   - at least `SNAP_TARGET_1`
5. Generate `STATE_ENCRYPTION_KEY` locally with:

   ```powershell
   powershell -ExecutionPolicy Bypass -File .\generate_state_key.ps1
   ```

6. In **Variables**, add `OPENAI_MODEL=gpt-5.4-nano`, `RUN_MODE=test`, and
   `BOT_ENABLED=false`.
7. Enable **Settings → Actions → General → Read and write permissions**.
8. Run `target_1` in `test` + `one_check` mode.
9. Run `target_1` in `live` + `max_updates=1` + `one_check` mode.
10. After checking Snapchat, run `live` + `max_updates=30` + `overnight`.

The public form exposes only a target slot name. Real Ad Account/Ad Squad identifiers,
product context, credentials, and encryption key remain GitHub Secrets. Bot retry history
is committed only as encrypted `state.json.enc`.

Read `README.md` before enabling scheduled work.
