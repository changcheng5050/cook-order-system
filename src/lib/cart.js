import { ref } from 'vue'

// 购物车状态（全局共享）
const cartItems = ref([])

export function useCart() {
  function addToCart(dish) {
    const exists = cartItems.value.find(item => item.id === dish.id)
    if (exists) return // 不允许重复添加
    cartItems.value.push({
      ...dish,
      customer_note: ''
    })
  }

  function removeFromCart(dishId) {
    cartItems.value = cartItems.value.filter(item => item.id !== dishId)
  }

  function updateNote(dishId, note) {
    const item = cartItems.value.find(item => item.id === dishId)
    if (item) item.customer_note = note
  }

  function clearCart() {
    cartItems.value = []
  }

  function getTotalTime() {
    return cartItems.value.reduce((sum, item) => sum + (item.cook_time || 0), 0)
  }

  return {
    cartItems,
    addToCart,
    removeFromCart,
    updateNote,
    clearCart,
    getTotalTime
  }
}
