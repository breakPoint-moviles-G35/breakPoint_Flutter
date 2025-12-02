# 🔧 Corrección de Zona Horaria en Reservas

## 📋 Problema Identificado

Existe un desajuste de zona horaria en el manejo de fechas de reservas entre el frontend (Flutter) y el backend.

### Síntoma:
- **Frontend envía**: Reserva para las 8:00 PM (hora local, Colombia UTC-5)
- **Backend guarda en Supabase**: 8:00 PM - 9:00 PM ✅ (correcto)
- **Backend devuelve al frontend**: Las fechas aparecen con un offset de 5 horas
- **Frontend muestra**: 1:00 AM - 2:00 AM ❌ (incorrecto)

### Ejemplo Real:
```
Usuario selecciona: 02/12/2025 20:00 (8 PM hora local Colombia)
Frontend envía: "2025-12-02T20:00:00.000Z" (convertido a UTC = 01:00 UTC del día siguiente)
Backend guarda: Correctamente como 8 PM
Backend devuelve: "2025-12-03T01:00:00.000Z" o similar
Frontend muestra: 1:00 AM (incorrecto)
```

---

## 🔍 Análisis del Frontend

### Lo que el Frontend está haciendo:

1. **Al ENVIAR reservas** (`POST /booking`):
   ```dart
   // Frontend convierte hora local a UTC antes de enviar
   final dateTimeLocal = DateTime(2025, 12, 2, 20, 0); // 8 PM hora local
   final dateTimeUtc = dateTimeLocal.toUtc(); // Convierte a UTC
   final isoString = dateTimeUtc.toIso8601String(); // "2025-12-03T01:00:00.000Z"
   ```

2. **Al RECIBIR reservas** (`GET /booking`, `GET /booking/closed`):
   ```dart
   // Frontend espera recibir fechas en UTC y las convierte a hora local
   // Si el backend devuelve "2025-12-03T01:00:00.000Z", el frontend lo convierte a:
   // 2025-12-02 20:00 (hora local Colombia) ✅
   ```

---

## ✅ Solución Requerida en el Backend

### Opción 1: Devolver fechas en UTC con indicador 'Z' (RECOMENDADO)

El backend debe **devolver siempre las fechas en formato UTC con el indicador 'Z'**:

```json
{
  "id": "...",
  "slotStart": "2025-12-03T01:00:00.000Z",  // ✅ UTC con 'Z'
  "slotEnd": "2025-12-03T02:00:00.000Z",    // ✅ UTC con 'Z'
  "status": "CONFIRMED"
}
```

**Por qué funciona:**
- El frontend espera recibir fechas en UTC
- El indicador 'Z' le dice al frontend que es UTC
- El frontend automáticamente convierte a hora local para mostrar

### Opción 2: Devolver fechas con offset de zona horaria

Si el backend quiere devolver fechas en hora local, debe incluir el offset:

```json
{
  "id": "...",
  "slotStart": "2025-12-02T20:00:00-05:00",  // Hora local con offset
  "slotEnd": "2025-12-02T21:00:00-05:00",    // Hora local con offset
  "status": "CONFIRMED"
}
```

---

## 🚫 Lo que NO debe hacer el Backend

### ❌ NO devolver fechas sin indicador de zona horaria:
```json
{
  "slotStart": "2025-12-02T20:00:00.000"  // ❌ Sin 'Z' ni offset
}
```
**Problema**: El frontend no sabe si es UTC o hora local, causando confusión.

### ❌ NO convertir UTC a hora local antes de devolver:
```json
{
  "slotStart": "2025-12-02T20:00:00.000Z"  // ❌ Si esto es UTC pero representa 8 PM local
}
```
**Problema**: Si el backend guarda en UTC pero devuelve como si fuera hora local, habrá desajuste.

---

## 📝 Endpoints Afectados

Los siguientes endpoints deben devolver fechas en formato UTC con 'Z':

1. `GET /booking` - Lista de reservas del usuario
2. `GET /booking/closed` - Reservas cerradas
3. `GET /booking/next` - Próximas reservas
4. `POST /booking` - Respuesta después de crear reserva
5. Cualquier otro endpoint que devuelva objetos con `slotStart` y `slotEnd`

---

## 🧪 Cómo Verificar

### Test 1: Crear reserva y verificar respuesta
```bash
POST /booking
Body: {
  "spaceId": "...",
  "slotStart": "2025-12-03T01:00:00.000Z",  # 8 PM Colombia en UTC
  "slotEnd": "2025-12-03T02:00:00.000Z",
  "guestCount": 1
}

# Respuesta debe tener:
{
  "slotStart": "2025-12-03T01:00:00.000Z",  # ✅ Mismo formato UTC
  "slotEnd": "2025-12-03T02:00:00.000Z"     # ✅ Mismo formato UTC
}
```

### Test 2: Obtener reservas y verificar formato
```bash
GET /booking

# Cada reserva debe tener:
{
  "slotStart": "2025-12-03T01:00:00.000Z",  # ✅ UTC con 'Z'
  "slotEnd": "2025-12-03T02:00:00.000Z"     # ✅ UTC con 'Z'
}
```

---

## 💡 Recomendación Final

**El backend debe:**
1. ✅ Aceptar fechas en UTC (con 'Z') del frontend
2. ✅ Guardar fechas en UTC en la base de datos
3. ✅ Devolver fechas en UTC (con 'Z') al frontend
4. ✅ **NO hacer conversiones de zona horaria** - dejar que el frontend maneje eso

**Formato estándar:**
```
"2025-12-03T01:00:00.000Z"
```
- `2025-12-03`: Fecha
- `T`: Separador fecha/hora
- `01:00:00`: Hora en UTC
- `.000`: Milisegundos
- `Z`: Indicador UTC (obligatorio)

---

## 📞 Si Necesitas Más Información

El frontend está usando:
- **Lenguaje**: Dart/Flutter
- **Zona horaria del usuario**: Colombia (UTC-5)
- **Librería de fechas**: `DateTime` nativo de Dart
- **Formato esperado**: ISO8601 con 'Z' para UTC

Si el backend devuelve las fechas en este formato, el frontend automáticamente las convertirá a hora local para mostrar al usuario.

