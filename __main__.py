"""AnonSuperApp - Point d'entrée principal."""

from core.app import app, engine
import uvicorn
import json

if __name__ == "__main__":
    print("=== AnonSuperApp v1.0.0 ===")
    print(json.dumps(engine.get_system_status(), indent=2, ensure_ascii=False))
    print("\nServeur API: http://localhost:8000")
    print("Docs: http://localhost:8000/docs")
    uvicorn.run(app, host="0.0.0.0", port=8000)
